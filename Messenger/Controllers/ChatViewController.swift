//
//  ChatViewController.swift
//  Messenger
//
//  Created by Dmytro Akulinin on 18.01.2023.
//

import UIKit
import MessageKit


struct Message: MessageType {
  var sender: MessageKit.SenderType
  var messageId: String
  var sentDate: Date
  var kind: MessageKit.MessageKind
  
  
}

struct Sender: SenderType {
  var senderId: String
  var displayName: String
  var photoURL: String
}


class ChatViewController: MessagesViewController {
  private var messages = [Message]()
  private let selfSender = Sender(senderId: "1", displayName: "John Smith", photoURL: "")
  override func viewDidLoad() {
    super.viewDidLoad()
    messages.append(Message(sender: selfSender, messageId: "1", sentDate: Date(), kind: .text("Hello World Message. Hello World Message. Hello World Message.")))
    messages.append(Message(sender: selfSender, messageId: "1", sentDate: Date(), kind: .text("Hello World Message. Hello World Message. Hello World Message.")))
    messages.append(Message(sender: selfSender, messageId: "1", sentDate: Date(), kind: .text("Hello World Message.")))
    view.backgroundColor = .red
    messagesCollectionView.messagesDataSource = self
    messagesCollectionView.messagesLayoutDelegate = self
    messagesCollectionView.messagesDisplayDelegate = self
    
  }
  
  
}

extension ChatViewController: MessagesDisplayDelegate, MessagesLayoutDelegate, MessagesDataSource {
  func currentSender() -> MessageKit.SenderType {
    selfSender
  }
  
  func messageForItem(at indexPath: IndexPath, in messagesCollectionView: MessageKit.MessagesCollectionView) -> MessageKit.MessageType {
    messages[indexPath.section]
  }
  
  func numberOfSections(in messagesCollectionView: MessageKit.MessagesCollectionView) -> Int {
    messages.count
  }
  
  
}
