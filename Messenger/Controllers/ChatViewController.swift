//
//  ChatViewController.swift
//  Messenger
//
//  Created by Dmytro Akulinin on 18.01.2023.
//

import UIKit
import MessageKit
import InputBarAccessoryView


struct Message: MessageType {
  public var sender: SenderType
  public var messageId: String
  public var sentDate: Date
  public var kind: MessageKind
  
  
}

extension MessageKind {
  var messageKindString: String {
    switch self {
      
    case .text(_):
      return "text"
    case .attributedText(_):
      return "attributed_text"
    case .photo(_):
      return "photo"
    case .video(_):
      return "video"
    case .location(_):
      return "location"
    case .emoji(_):
      return "emoji"
    case .audio(_):
      return "audio"
    case .contact(_):
      return "contact"
    case .linkPreview(_):
      return "link_preview"
    case .custom(_):
      return "custom"
    }
  }
}

struct Sender: SenderType {
  public var senderId: String
  public var displayName: String
  public var photoURL: String
}


class ChatViewController: MessagesViewController {
  public static var dateFormatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.dateStyle = .medium
    formatter.timeStyle = .long
    formatter.locale = .current
    return formatter
  }()
  
  public var isNewConversation = false
  public var otherUserEmail: String
  
  private var messages = [Message]()
  private var selfSender: Sender? {
    
    guard let email = UserDefaults.standard.value(forKey: "email") as? String else {
      return nil
    }
    
    return Sender(senderId: email,
           displayName: "John Smith",
           photoURL: "")
    
  }
  init(with email: String) {
    self.otherUserEmail = email
    super.init(nibName: nil, bundle: nil)
  }
  
  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
  
  override func viewDidLoad() {
    super.viewDidLoad()
    
    view.backgroundColor = .red
    messagesCollectionView.messagesDataSource = self
    messagesCollectionView.messagesLayoutDelegate = self
    messagesCollectionView.messagesDisplayDelegate = self
    messageInputBar.delegate = self
  }
  
  override func viewDidAppear(_ animated: Bool) {
    super.viewDidAppear(animated)
    messageInputBar.inputTextView.becomeFirstResponder()
  }
  
  
}

extension ChatViewController: InputBarAccessoryViewDelegate {
  func inputBar(_ inputBar: InputBarAccessoryView, didPressSendButtonWith text: String) {
    guard !text.replacingOccurrences(of: " ", with: "").isEmpty,
          let selfSender = self.selfSender,
          let messageId = createMessageID() else {
      return
    }
    
    // Send Message
    print("sending \(text)")
    if isNewConversation {
      let message = Message(sender: selfSender,
                            messageId: messageId,
                            sentDate: Date(),
                            kind: .text(text))
      DatabaseManager.shared.createNewConversation(with: otherUserEmail, firstMessage: message, completion: {[weak self] success in
        if success {
          print("message sent")
        } else {
          print("failed to send")
        }
      })
    } else {
      // append to existing conversation date
    }
    
  }
  
  private func createMessageID() -> String? {
    // date, otherUserEmail, senderEmail, randomInt
    

    guard let currentUserEmail = UserDefaults.standard.value(forKey: "email") as? String else {
            return nil
          }
    let safeCurrentEmail = DatabaseManager.safeEmail(emailAdress: currentUserEmail)
    let dateString = Self.dateFormatter.string(from: Date())
    let newIdentifier = ("\(otherUserEmail)_\(safeCurrentEmail)")
    print("created message id: \(newIdentifier)")
    return newIdentifier
  }
}

extension ChatViewController: MessagesDisplayDelegate, MessagesLayoutDelegate, MessagesDataSource {
  func currentSender() -> MessageKit.SenderType {
    if let sender = selfSender {
      return sender
    }
    fatalError("Self Sender is nil")
    return Sender(senderId: "1", displayName: "", photoURL: "")
  }
  
  func messageForItem(at indexPath: IndexPath, in messagesCollectionView: MessageKit.MessagesCollectionView) -> MessageKit.MessageType {
    messages[indexPath.section]
  }
  
  func numberOfSections(in messagesCollectionView: MessageKit.MessagesCollectionView) -> Int {
    messages.count
  }
  
  
}
