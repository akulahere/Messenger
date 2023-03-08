//
//  ViewController.swift
//  Messenger
//
//  Created by Dmytro Akulinin on 05.01.2023.
//

import UIKit
import FirebaseAuth
import JGProgressHUD

struct Conversation {
  let id: String
  let name: String
  let otherUserEmail: String
  let latestMessage: LatestMessage
}

struct LatestMessage {
  let date: String
  let text: String
  let isRead: Bool
}

class ConversationViewController: UIViewController {
  
  private let spinner = JGProgressHUD(style: .dark)
  
  private var conversations = [Conversation]()
  
  private let tableView: UITableView = {
    let table = UITableView()
    table.isHidden = true
    table.register(ConversationTableViewCell.self,
                   forCellReuseIdentifier: ConversationTableViewCell.identifier)
    return table
  }()
  
  private let noConversationLabel: UILabel = {
    let label = UILabel()
    label.text = "No Conversation!"
    label.textAlignment = .center
    label.textColor = .gray
    
    label.font = UIFont.systemFont(ofSize: 21)
    label.isHidden = true
    return label
  }()

  override func viewDidLoad() {
    super.viewDidLoad()
    navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .compose, target: self, action: #selector(didTapComposeButton))
    view.addSubview(tableView)
    view.addSubview(noConversationLabel)
    setupTableView()
    fetchConversation()
    startListeningForConversations()
  }
  
  private func startListeningForConversations() {
    guard let email = UserDefaults.standard.value(forKey: "email") as? String else {
      return
    }

    let safeEmail = DatabaseManager.safeEmail(emailAdress: email)
    DatabaseManager.shared.getAllConversations(for: safeEmail) { [weak self] result in
      switch result {
      case .success(let conversations):
        guard !conversations.isEmpty else {
          return
        }
        self?.conversations = conversations
        DispatchQueue.main.async {
          self?.tableView.reloadData()
        }
      case .failure(let error):
        print("failed to get convos: \(error)")
      }
    }
  }
  
  override func viewDidLayoutSubviews() {
    super.viewDidLayoutSubviews()
    tableView.frame = view.bounds
  }
  
  override func viewDidAppear(_ animated: Bool) {
    super.viewDidAppear(animated)
    validateAuth()
  }
  
  @objc private func didTapComposeButton() {
    let vc = NewConversationViewController()
    vc.completion = {[weak self] result in
      print("\(result)")
      self?.createNewConversation(results: result)
    }
    let navVC = UINavigationController(rootViewController: vc)
    present(navVC, animated: true)
  }
  
  private func createNewConversation(results: [String: String]) {

    
    guard let name = results["name"],
          let email = results["email"] else {
      return
    }
    let vc = ChatViewController(with: email, id: nil)
    vc.isNewConversation = true
    vc.title = name
    vc.navigationItem.largeTitleDisplayMode = .never
    navigationController?.pushViewController(vc, animated: true)
  }
  
  private func validateAuth() {
    if FirebaseAuth.Auth.auth().currentUser == nil {
      let vc = LoginViewController()
      let nav = UINavigationController(rootViewController: vc)
      nav.modalPresentationStyle = .fullScreen
      present(nav, animated: false)
    }
  }
  
  private func setupTableView() {
    tableView.delegate = self
    tableView.dataSource = self
  }
  
  private func fetchConversation() {
    tableView.isHidden = false
  }


}


extension ConversationViewController: UITableViewDelegate, UITableViewDataSource {
  func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    return conversations.count
  }
  
  func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    
    let model = conversations[indexPath.row]
    let cell = tableView.dequeueReusableCell(withIdentifier: ConversationTableViewCell.identifier,
                                             for: indexPath) as! ConversationTableViewCell
    cell.configure(with: model)
    return cell
  }
  
  func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
    tableView.deselectRow(at: indexPath, animated: true)
    let model = conversations[indexPath.row]
    let vc = ChatViewController(with: model.otherUserEmail, id: model.id)
    vc.title = model.name
    vc.navigationItem.largeTitleDisplayMode = .never
    navigationController?.pushViewController(vc, animated: true)
  }
  
  func tableView(_ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat {
    return 120
  }
}
