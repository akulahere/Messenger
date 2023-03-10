//
//  DatabaseManager.swift
//  Messenger
//
//  Created by Dmytro Akulinin on 11.01.2023.
//

import Foundation
import FirebaseDatabase

final class DatabaseManager {
  static let shared = DatabaseManager()
  
  private let database = Database.database().reference()
  
  static func safeEmail(emailAdress: String) -> String {
    var safeEmail = emailAdress.replacingOccurrences(of: ".", with: "-")
    safeEmail = safeEmail.replacingOccurrences(of: "@", with: "-")
    return safeEmail
  }
  
}

// MARK: - Account Management
extension DatabaseManager {
  public func userExists(with email: String, completion: @escaping ((Bool) -> Void)) {
    var safeEmail = email.replacingOccurrences(of: ".", with: "-")
    safeEmail = safeEmail.replacingOccurrences(of: "@", with: "-")
    print(safeEmail)
    
    database.child(safeEmail).observeSingleEvent(of: .value) { snapshot in
      
      guard snapshot.value as? String != nil else {
        completion(false)
        return
      }
      completion(true)
    }
  }
  
  /// Inserts new user to database
  public func insertUser(with user: ChatAppUser, completion: @escaping (Bool) -> Void) {
    database.child(user.safeEmail).setValue([
      "first_name": user.firstName,
      "last_name": user.lastName
    ]) { error, _ in
      guard error == nil else {
        print("!!!failed to write to database!!!")
        completion(false)
        return
      }
      self.database.child("users").observeSingleEvent(of: .value) { snapshot in
        if var usersCollection = snapshot.value as? [[String: String]] {
          // append to usedr array
          let newElement = [
            "name": user.firstName + " " + user.lastName,
            "email": user.safeEmail
          ]
          usersCollection.append(newElement)
          self.database.child("users").setValue(usersCollection) { error, _ in
            guard error == nil else {
              completion(false)
              return
            }
            
            completion(true)
          }
          
        } else {
          let newCollection: [[String: String]] = [
            [
              "name": user.firstName + " " + user.lastName,
              "email": user.safeEmail
            ]
          ]
          
          self.database.child("users").setValue(newCollection) { error, _ in
            guard error == nil else {
              completion(false)
              return
            }
            
            completion(true)
          }
        }
      }
      
      
      completion(true)
    }
  }
  
  public func getAllUsers(completion: @escaping (Result<[[String: String]], Error>) -> Void) {
    database.child("users").observeSingleEvent(of: .value) { snapshot in
      guard let value = snapshot.value as? [[String: String]] else {
        completion(.failure(DatabaseError.failedToFetch))
        return
      }
      
      completion(.success(value))
    }
  }
  
  public enum DatabaseError: Error {
    case failedToFetch
  }
}

// MARK: - Sending messages / conversations

extension DatabaseManager {
  /// Creates a new conversation with target use email and first message sent
  public func createNewConversation(with otherUserEmail: String, name: String,  firstMessage: Message, completion: @escaping (Bool) -> Void) {
    guard let currentEmail = UserDefaults.standard.value(forKey: "email") as? String else {
      return
    }
    
    let safeEmail = DatabaseManager.safeEmail(emailAdress: currentEmail)
    
    let ref = database.child("\(safeEmail)")
    
    ref.observeSingleEvent(of: .value, with: {[weak self] snapshot in
      guard var userNode = snapshot.value as? [String: Any] else {
        completion(false)
        print("user not found")
        return
      }
      
      let messageDate = firstMessage.sentDate
      let dateString = ChatViewController.dateFormatter.string(from: messageDate)
      
      var message = ""
      
      switch firstMessage.kind {
        
      case .text(let messageText):
        message = messageText
      case .attributedText(_):
        break
      case .photo(_):
        break
      case .video(_):
        break
      case .location(_):
        break
      case .emoji(_):
        break
      case .audio(_):
        break
      case .contact(_):
        break
      case .linkPreview(_):
        break
      case .custom(_):
        break
      }
      
      let conversationID = "conversation_\(firstMessage.messageId)"
      
      let newConversationData: [String: Any] = [
        "id": conversationID ,
        "other_user_email": otherUserEmail,
        "name": name,
        "latest_message": [
          "date": dateString,
          "message": message,
          "is_read": false
        ]
      ]
      
      let recipientNewConversationData: [String: Any] = [
        "id": conversationID ,
        "other_user_email": safeEmail,
        "name": "Self",
        "latest_message": [
          "date": dateString,
          "message": message,
          "is_read": false
        ]
      ]
      
      // Update recipient conversation entry
      
      self?.database.child("\(otherUserEmail)/conversations").observeSingleEvent(of: .value) {[weak self] snapshot in
        if var conversations = snapshot.value as? [[String: Any]] {
          // append
          conversations.append(recipientNewConversationData)
          self?.database.child("\(otherUserEmail)/conversations").setValue(conversationID)

        } else {
          // create
          self?.database.child("\(otherUserEmail)/conversations").setValue(recipientNewConversationData)
        }
      }
      // Update current user conversation entry
      if var conversations = userNode["conversations"] as? [[String: Any]] {
        // conversation array exists for current user
        // you should append
        conversations.append(newConversationData)
        userNode["conversations"] = conversations
        
        ref.setValue(userNode, withCompletionBlock: { [weak self] error, _ in
          guard error == nil else {
            completion(false)
            return
          }
          self?.finishCreatingConversation(name: name,
                                           conversationID: conversationID,
                                           firstMessage: firstMessage,
                                           completion: completion)
          
        })
        
      } else {
        //conversation array does not exist
        //create it
        userNode["conversations"] = [
          newConversationData
        ]
        
        ref.setValue(userNode, withCompletionBlock: { [weak self] error, _ in
          guard error == nil else {
            completion(false)
            return
          }
          
          self?.finishCreatingConversation(name: name,
                                           conversationID: conversationID,
                                           firstMessage: firstMessage,
                                           completion: completion)
        })
      }
    })
  }
  
  private func finishCreatingConversation(name: String, conversationID: String, firstMessage: Message, completion: @escaping (Bool) -> Void) {
    
    var message = ""
    
    let messageDate = firstMessage.sentDate
    let dateString = ChatViewController.dateFormatter.string(from: messageDate)
    
    switch firstMessage.kind {
      
    case .text(let messageText):
      message = messageText
    case .attributedText(_):
      break
    case .photo(_):
      break
    case .video(_):
      break
    case .location(_):
      break
    case .emoji(_):
      break
    case .audio(_):
      break
    case .contact(_):
      break
    case .linkPreview(_):
      break
    case .custom(_):
      break
    }
    
    guard let myEmail = UserDefaults.standard.value(forKey: "email") as? String else {
      completion(false)
      return
    }
    let currentUserEmail = DatabaseManager.safeEmail(emailAdress: myEmail)
    
    let collectionMessage: [String: Any] = [
      "id": firstMessage.messageId,
      "type": firstMessage.kind.messageKindString,
      "content": message,
      "date": dateString,
      "sender_email": currentUserEmail,
      "is_read": false,
      "name": name
    ]
    
    let value: [String: Any] = [
      "messages": [
        collectionMessage
      ]
    ]
    database.child("\(conversationID)").setValue(value, withCompletionBlock: {
      error, _ in
      guard error == nil else {
        completion(false)
        return
      }
      completion(true)
    })
  }
  
  /// Fetches and returns all conversation for the user with passed in email
  public func getAllConversations(for email: String, completion: @escaping (Result<[Conversation], Error>) -> Void) {
    database.child("\(email)/conversations").observe(.value) { snapshot in
      guard let value = snapshot.value as? [[String: Any]] else {
        completion(.failure(DatabaseError.failedToFetch))
        return
      }
      
      let conversations: [Conversation] = value.compactMap { dictionary -> Conversation? in
        guard let conversationId = dictionary["id"] as? String,
              let name = dictionary["name"] as? String,
              let otherUserEmail = dictionary["other_user_email"] as? String,
              let latestMessage = dictionary["latest_message"] as? [String: Any],
              let date = latestMessage["date"] as? String,
              let message = latestMessage["message"] as? String,
              let isRead = latestMessage["is_read"] as? Bool else {
          return nil
        }

        let latestMessageObject = LatestMessage(date: date,
                                                text: message,
                                                isRead: isRead)

        return Conversation(id: conversationId,
                            name: name,
                            otherUserEmail: otherUserEmail,
                            latestMessage: latestMessageObject)
      }
      completion(.success(conversations))
    }
  }
  
  /// Gets all messages for a given conversation
  public func getAllMessagesForConversation(with id: String, completion: @escaping (Result<[Message], Error>) -> Void) {
    database.child("\(id)/messages").observe(.value) { snapshot in
      guard let value = snapshot.value as? [[String: Any]] else {
        completion(.failure(DatabaseError.failedToFetch))
        return
      }
      
      let messages: [Message] = value.compactMap { dictionary in
        guard let name = dictionary["name"] as? String,
              let isRead = dictionary["is_read"] as? Bool,
              let messageID = dictionary["id"] as? String,
              let content = dictionary["content"] as? String,
              let senderEmail = dictionary["sender_email"] as? String,
              let type = dictionary["type"] as? String,
              let dateString = dictionary["date"] as? String,
              let date = ChatViewController.dateFormatter.date(from: dateString) else {
          return nil
        }
        let sender = Sender(senderId: senderEmail, displayName: name, photoURL: "")
        return Message(sender: sender,
                       messageId: messageID,
                       sentDate: date,
                       kind: .text(content))
      }
      
      completion(.success(messages))
    }

  }
  
  /// Send a message with target conversation and message
  public func sendMessage(to conversation: String, message: Message, completion: @escaping (Bool) -> Void) {
    
  }
  
}


struct ChatAppUser: Hashable {
  let firstName: String
  let lastName: String
  let emailAdress: String
  
  var safeEmail: String {
    var safeEmail = emailAdress.replacingOccurrences(of: ".", with: "-")
    safeEmail = safeEmail.replacingOccurrences(of: "@", with: "-")
    return safeEmail
  }
  
  var profilePictureFileName: String {
    return "\(safeEmail)_profile_picture.png"
  }
}
