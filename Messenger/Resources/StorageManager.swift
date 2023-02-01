//
//  StorageManager.swift
//  Messenger
//
//  Created by Dmytro Akulinin on 19.01.2023.
//

import Foundation
import FirebaseStorage

final class StorageManager {
  
  static let shared = StorageManager()
  
  private let storage = Storage.storage().reference()
  
  public typealias UploadPictureCompeletion = (Result<String, Error>) -> Void
  
  /// Upload picture to firebase storage and returns completion with url string to download
  public func uploadProfilePicture(with data: Data, fileName: String, completion: @escaping UploadPictureCompeletion) {
    storage.child("images/\(fileName)").putData(data, completion: { metadata, error in
      guard error == nil else {
        //failed
        print("Failed to upload data to firebase")
        completion(.failure(StorageErrors.failedToUpload))
        return
      }
      
      self.storage.child("images/\(fileName)").downloadURL { url, error in
        guard let url = url else {
          print("")
          completion(.failure(StorageErrors.failedToGetDownloadUrl))
          return
        }
        
        let urlString = url.absoluteString
        print("download url returned: \(urlString)")
        completion(.success(urlString))
      }
    })
  }
  
  public enum StorageErrors: Error {
    case failedToUpload
    case failedToGetDownloadUrl
    
  }
  
  public func downloadURL(for path: String, completion: @escaping (Result<URL, Error>) -> Void) {
    let reference = storage.child(path)
    
    reference.downloadURL(completion: { url, error in
      guard let url = url, error == nil else {
        print(reference)
        print("PROBLEM IN STORAGEMANAGER")
        completion(.failure(StorageErrors.failedToGetDownloadUrl))
        return
      }
      
      completion(.success(url))
      
    })
  }
  
}
