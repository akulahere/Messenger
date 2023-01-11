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
  public func insertUser(with user: ChatAppUser) {
    database.child(user.safeEmail).setValue([
      "first_name": user.firstName,
      "last_name": user.lastName
    ])
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
}
