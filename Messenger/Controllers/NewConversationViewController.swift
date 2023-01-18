//
//  NewConversationViewController.swift
//  Messenger
//
//  Created by Dmytro Akulinin on 05.01.2023.
//

import UIKit
import JGProgressHUD

class NewConversationViewController: UIViewController {
  private let spinner = JGProgressHUD()
  private let searchBar: UISearchBar = {
    let searchBar = UISearchBar()
    searchBar.placeholder = "Search for Users..."
    return searchBar
  }()
  
  private let tableView: UITableView = {
    let table = UITableView()
    table.register(UITableViewCell.self, forCellReuseIdentifier: "cell")
    return table
  }()
  
  private let noResultLabel: UILabel = {
    let label = UILabel()
    label.text = "No Results"
    label.textAlignment = .center
    label.textColor = .green
    label.font = .systemFont(ofSize: 21, weight: .medium)
    return label
  }()
  
  override func viewDidLoad() {
    super.viewDidLoad()
    searchBar.delegate = self
    view.backgroundColor = .white
    navigationController?.navigationBar.topItem?.titleView = searchBar
    navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Cancel", style: .done, target: self, action: #selector(dismissSelf))
    searchBar.becomeFirstResponder()
  }
    
  @objc private func dismissSelf() {
    dismiss(animated: true)
  }
}


extension NewConversationViewController: UISearchBarDelegate {
  func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
    
  }
}
