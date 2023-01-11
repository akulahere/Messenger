//
//  RegisterViewController.swift
//  Messenger
//
//  Created by Dmytro Akulinin on 05.01.2023.
//

import UIKit
import FirebaseAuth

class RegisterViewController: UIViewController {
  
  
  
  
  private let scrollView: UIScrollView = {
    let scrollView = UIScrollView()
    scrollView.clipsToBounds = true
    return scrollView
  }()
  
  private let imageView: UIImageView = {
    let imageView = UIImageView()
    imageView.image = UIImage(systemName: "person.circle")
    imageView.tintColor = .gray
    imageView.contentMode = .scaleAspectFit
    imageView.layer.masksToBounds = true
    imageView.layer.borderWidth = 2
    imageView.layer.borderColor = UIColor.lightGray.cgColor
    
    return imageView
  }()
  
  private let emailField: UITextField = {
    let field = UITextField()
    field.autocapitalizationType = .none
    field.autocorrectionType = .no
    field.returnKeyType = .done
    field.layer.cornerRadius = 12
    field.layer.borderWidth = 1
    field.layer.borderColor = UIColor.lightGray.cgColor
    field.placeholder = "Enter your email address"
    field.leftView = UIView(frame: CGRect(x: 0, y: 0, width: 5, height: 0))
    field.leftViewMode = .always
    field.backgroundColor = .white
    return field
  }()
  
  private let firstNameField: UITextField = {
    let field = UITextField()
    field.autocapitalizationType = .none
    field.autocorrectionType = .no
    field.returnKeyType = .done
    field.layer.cornerRadius = 12
    field.layer.borderWidth = 1
    field.layer.borderColor = UIColor.lightGray.cgColor
    field.placeholder = "Enter your first name"
    field.leftView = UIView(frame: CGRect(x: 0, y: 0, width: 5, height: 0))
    field.leftViewMode = .always
    field.backgroundColor = .white
    return field
  }()
  
  private let lastNameField: UITextField = {
    let field = UITextField()
    field.autocapitalizationType = .none
    field.autocorrectionType = .no
    field.returnKeyType = .done
    field.layer.cornerRadius = 12
    field.layer.borderWidth = 1
    field.layer.borderColor = UIColor.lightGray.cgColor
    field.placeholder = "Enter your second name"
    field.leftView = UIView(frame: CGRect(x: 0, y: 0, width: 5, height: 0))
    field.leftViewMode = .always
    field.backgroundColor = .white
    return field
  }()
  
  private let passwordField: UITextField = {
    let field = UITextField()
    field.autocapitalizationType = .none
    field.autocorrectionType = .no
    field.returnKeyType = .continue
    field.layer.cornerRadius = 12
    field.layer.borderWidth = 1
    field.layer.borderColor = UIColor.lightGray.cgColor
    field.placeholder = "Enter your password"
    field.leftView = UIView(frame: CGRect(x: 0, y: 0, width: 5, height: 0))
    field.leftViewMode = .always
    field.isSecureTextEntry = true
    field.backgroundColor = .white
    return field
  }()
  
  private let registerButton: UIButton = {
    let button = UIButton()
    button.setTitle("Register", for: .normal)
    button.backgroundColor = .link
    button.setTitleColor(.white, for: .normal)
    button.layer.cornerRadius = 12
    button.layer.masksToBounds = true
    button.titleLabel?.font = .systemFont(ofSize: 20, weight: .bold)
    return button
  }()
  
  
  
  override func viewDidLoad() {
    super.viewDidLoad()
    title = "Register"
    view.backgroundColor = .white
    navigationItem.rightBarButtonItem  = UIBarButtonItem(title: "Log In", style: .done, target: self, action: #selector(didTapRegister))
    
    
    registerButton.addTarget(self, action: #selector(registerButtonTapped), for: .touchUpInside)
    
    emailField.delegate = self
    passwordField.delegate = self
    
    // Add subviews
    view.addSubview(scrollView)
    scrollView.addSubview(imageView)
    scrollView.addSubview(emailField)
    scrollView.addSubview(firstNameField)
    scrollView.addSubview(lastNameField)
    scrollView.addSubview(passwordField)
    scrollView.addSubview(registerButton)
    
    imageView.isUserInteractionEnabled = true
    let gesture = UITapGestureRecognizer(target: self, action: #selector(didTapChangeProfilePic))
    gesture.numberOfTapsRequired = 1
    imageView.addGestureRecognizer(gesture)
    
    
  }
  
  @objc private func didTapChangeProfilePic() {
    print("Change pic called")
    presentPhotoActionSheet()
  }
  
  override func viewDidLayoutSubviews() {
    super.viewDidLayoutSubviews()
    scrollView.frame = view.bounds
    let size = scrollView.width / 3
    imageView.frame = CGRect(x: (scrollView.width - size) / 2, y: 20, width: size, height: size)
    firstNameField.frame = CGRect(x: 30, y: imageView.bottom + 10, width: scrollView.width - 60, height: 52 )
    lastNameField.frame = CGRect(x: 30, y: firstNameField.bottom + 10, width: scrollView.width - 60, height: 52 )
    emailField.frame = CGRect(x: 30, y: lastNameField.bottom + 10, width: scrollView.width - 60, height: 52 )
    passwordField.frame = CGRect(x: 30, y: emailField.bottom + 10, width: scrollView.width - 60, height: 52 )
    registerButton.frame = CGRect(x: 30, y: passwordField.bottom + 10, width: scrollView.width - 60, height: 52 )
    imageView.layer.cornerRadius = imageView.width / 2.0
    
    
    
  }
  
  @objc private func registerButtonTapped() {
    emailField.resignFirstResponder()
    passwordField.resignFirstResponder()
    firstNameField.resignFirstResponder()
    lastNameField.resignFirstResponder()
    
    guard let firstName = firstNameField.text,
          let lastName = lastNameField.text,
          let email = emailField.text,
          let password = passwordField.text,
          !email.isEmpty,
          !password.isEmpty,
          !firstName.isEmpty,
          !lastName.isEmpty,
          password.count >= 6 else {
      alertUserLoginError()
      return
    }
    // Firebase login
    
    FirebaseAuth.Auth.auth().createUser(withEmail: email, password: password) { [weak self] authResult, error in
      
      guard let strongSelf = self else {
        return
      }
      guard let result = authResult, error == nil else {
        print("Error creating user")
        return
      }
      
      let user = result.user
      print("Created user: \(user)")
      strongSelf.navigationController?.dismiss(animated: true)

    }
  }
  
  func alertUserLoginError() {
    let alert = UIAlertController(title: "Woops", message: "Please enter all information to create account", preferredStyle: .alert)
    alert.addAction(UIAlertAction(title: "Dismiss", style: .cancel))
    present(alert, animated: true)
  }
  
  @objc private func didTapRegister() {
    let vc = RegisterViewController()
    vc.title = "Create Account"
    navigationController?.pushViewController(vc, animated: true)
  }
  
  /*
   // MARK: - Navigation
   
   // In a storyboard-based application, you will often want to do a little preparation before navigation
   override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
   // Get the new view controller using segue.destination.
   // Pass the selected object to the new view controller.
   }
   */
  
  
}



extension RegisterViewController: UITextFieldDelegate {
  func textFieldShouldReturn(_ textField: UITextField) -> Bool {
    if textField == emailField {
      passwordField.becomeFirstResponder()
    } else if textField == passwordField {
      registerButtonTapped()
    }
    return true
  }
}


// TODO: - Refactor with PHPicker. UIImagePickerController.sourceType.photoLibrary will be deprecated

extension RegisterViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
  
  func presentPhotoActionSheet() {
    let actionSheet = UIAlertController(title: "Profile Picture", message: "How would you like select a picture?", preferredStyle: .actionSheet)
    actionSheet.addAction(UIAlertAction(title: "Cancel", style: .cancel))
    actionSheet.addAction(UIAlertAction(title: "Take Photo", style: .default, handler: {[weak self] _ in
      self?.presentCamera()
    }))
    actionSheet.addAction(UIAlertAction(title: "Choose Photo", style: .default, handler: {[weak self] _ in
      self?.presentPhotoPicker()
    }))
    
    present(actionSheet, animated: true)
  }
  
  func presentCamera() {
    let vc = UIImagePickerController()
    vc.sourceType = .camera
    vc.delegate = self
    vc.allowsEditing = true
    present(vc, animated: true)
  }
  
  func presentPhotoPicker() {
    let vc = UIImagePickerController()
    vc.sourceType = .photoLibrary
    vc.delegate = self
    vc.allowsEditing = true
    present(vc, animated: true)
  }
  
  func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
    picker.dismiss(animated: true)
    print(info)
    guard let selectedImage = info[UIImagePickerController.InfoKey.editedImage] as? UIImage else {
      return
    }
    
    self.imageView.image = selectedImage
  }
  
  func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
    
  }
}
