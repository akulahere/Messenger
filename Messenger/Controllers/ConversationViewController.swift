//
//  ViewController.swift
//  Messenger
//
//  Created by Dmytro Akulinin on 05.01.2023.
//

import UIKit
import FirebaseAuth

class ConversationViewController: UIViewController {

  override func viewDidLoad() {
    super.viewDidLoad()
    view.backgroundColor = .red
  }
  override func viewDidAppear(_ animated: Bool) {
    super.viewDidAppear(animated)
    let isLoggedIn = UserDefaults.standard.bool(forKey: "logged_in")
    if !isLoggedIn {
      let vc = LoginViewController()
      let nav = UINavigationController(rootViewController: vc)
      nav.modalPresentationStyle = .fullScreen
      present(nav, animated: false)
    }
  }
  


}

