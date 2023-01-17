//
//  LoginViewController.swift
//  Messenger
//
//  Created by Dmytro Akulinin on 05.01.2023.
//

import UIKit
import FirebaseAuth
import FBSDKLoginKit
import GoogleSignIn
import GoogleSignInSwift

class LoginViewController: UIViewController {
  
  private let scrollView: UIScrollView = {
    let scrollView = UIScrollView()
    scrollView.clipsToBounds = true
    return scrollView
  }()
  
  private let imageView: UIImageView = {
    let imageView = UIImageView()
    imageView.image = UIImage(named: "Logo")
    imageView.contentMode = .scaleAspectFit
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
  
  private let loginButton: UIButton = {
    let button = UIButton()
    button.setTitle("Log In", for: .normal)
    button.backgroundColor = .link
    button.setTitleColor(.white, for: .normal)
    button.layer.cornerRadius = 12
    button.layer.masksToBounds = true
    button.titleLabel?.font = .systemFont(ofSize: 20, weight: .bold)
    return button
  }()
  
  private let fbLoginButton: FBLoginButton = {
    let button = FBLoginButton()
    button.permissions = ["email","public_profile"]
    return button
  }()
  
  private let googleLogInButton = GIDSignInButton()

  private var loginObserver: NSObjectProtocol?
  
  override func viewDidLoad() {
    super.viewDidLoad()
    
    loginObserver = NotificationCenter.default.addObserver(forName: .didLogInNotification, object: nil, queue: .main, using: {[weak self] _ in
      guard let strongSelf = self else {
        return
      }
      strongSelf.navigationController?.dismiss(animated: true, completion: {})
      
    })
    
    title = "Log In"
    view.backgroundColor = .white
    navigationItem.rightBarButtonItem  = UIBarButtonItem(title: "Register", style: .done, target: self, action: #selector(didTapRegister))
    
    
    loginButton.addTarget(self, action: #selector(loginButtonTapped), for: .touchUpInside)
    googleLogInButton.addTarget(self, action: #selector(googleSignInButtonTapped), for: .touchUpInside)
    
    emailField.delegate = self
    passwordField.delegate = self
    
    fbLoginButton.delegate = self
    
    // Add subviews
    view.addSubview(scrollView)
    scrollView.addSubview(imageView)
    scrollView.addSubview(emailField)
    scrollView.addSubview(passwordField)
    scrollView.addSubview(loginButton)
    scrollView.addSubview(fbLoginButton)
    scrollView.addSubview(googleLogInButton)
    
  }
  
  deinit {
    if let observer = loginObserver {
      NotificationCenter.default.removeObserver(observer)
    }
  }
  
  override func viewDidLayoutSubviews() {
    super.viewDidLayoutSubviews()
    scrollView.frame = view.bounds
    let size = scrollView.width / 3
    imageView.frame = CGRect(x: (scrollView.width - size) / 2, y: 20, width: size, height: size)
    emailField.frame = CGRect(x: 30, y: imageView.bottom + 10, width: scrollView.width - 60, height: 52 )
    passwordField.frame = CGRect(x: 30, y: emailField.bottom + 10, width: scrollView.width - 60, height: 52 )
    loginButton.frame = CGRect(x: 30, y: passwordField.bottom + 10, width: scrollView.width - 60, height: 52 )
    
    fbLoginButton.frame = CGRect(x: 30, y: passwordField.bottom + 10, width: scrollView.width - 60, height: 52 )
    fbLoginButton.frame.origin.y = loginButton.bottom + 20
    
    googleLogInButton.frame = CGRect(x: 30, y: passwordField.bottom + 10, width: scrollView.width - 60, height: 52 )
    googleLogInButton.frame.origin.y = fbLoginButton.bottom + 20
  }
  //Google Sign In
  
  @objc private func googleSignInButtonTapped() {

    
    
    GIDSignIn.sharedInstance.signIn(withPresenting: self) {signInResult, error in
      guard error == nil else {
        return
      }
      guard let signInResult = signInResult else { return }
      
      let user = signInResult.user
      
      guard let emailAddress = user.profile?.email else {
        // no email on google user
        return
      }
      
      let firstName = user.profile?.givenName ?? "No first name"
      let lastName = user.profile?.familyName ?? "No second name"
      //      let profilePicUrl = user.profile?.imageURL(withDimension: 320)

      DatabaseManager.shared.userExists(with: emailAddress) { exists in
        if !exists {
          // add new user to DB
          DatabaseManager.shared.insertUser(with: ChatAppUser(firstName: firstName, lastName: lastName, emailAdress: emailAddress))
        }
      }
      
      let accessToken = user.accessToken.tokenString
      guard let idToken = user.idToken?.tokenString else { return }
      let credential = GoogleAuthProvider.credential(withIDToken: idToken,
                                                       accessToken: accessToken)
      
      Auth.auth().signIn(with: credential) { [weak self] authResult, error in
        guard let strongSelf = self else {
          return
        }
        guard let result = authResult, error == nil else {
          print("Failed to log in user with email: \(emailAddress)")
          return
        }
        
        let user = result.user
        print("Logged in \(user)")
        strongSelf.navigationController?.dismiss(animated: true)
      }
      
      NotificationCenter.default.post(name: .didLogInNotification, object: nil)
    }
  }
  
  @objc private func loginButtonTapped() {
    emailField.resignFirstResponder()
    passwordField.resignFirstResponder()
    guard let email = emailField.text, let password = passwordField.text, !email.isEmpty, !password.isEmpty, password.count >= 6 else {
      alertUserLoginError()
      return
    }
    //TODO: Firebase login
    
    FirebaseAuth.Auth.auth().signIn(withEmail: email, password: password) {[weak self] authResult, error in
      
      guard let strongSelf = self else {
        return
      }
      guard let result = authResult, error == nil else {
        print("Failed to log in user with email: \(email)")
        return
      }
      
      let user = result.user
      print("Logged in \(user)")
      strongSelf.navigationController?.dismiss(animated: true)
    }
  }
  
  func alertUserLoginError() {
    let alert = UIAlertController(title: "Woops", message: "Please enter all information to log in", preferredStyle: .alert)
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


extension LoginViewController: UITextFieldDelegate {
  func textFieldShouldReturn(_ textField: UITextField) -> Bool {
    if textField == emailField {
      passwordField.becomeFirstResponder()
    } else if textField == passwordField {
      loginButtonTapped()
    }
    return true
  }
}

extension LoginViewController: LoginButtonDelegate {
  func loginButtonDidLogOut(_ loginButton: FBSDKLoginKit.FBLoginButton) {
    // no operation
  }
  
  func loginButton(_ loginButton: FBLoginButton, didCompleteWith result: LoginManagerLoginResult?, error: Error?) {
    guard let token = result?.token?.tokenString else {
      print("User failed to log in with facebook")
      return
    }
    
    let facebookRequest = FBSDKLoginKit.GraphRequest(graphPath: "me", parameters: ["fields": "email, name"], tokenString: token, version: nil, httpMethod: .get)
    
    facebookRequest.start { _, result, error in
      guard let result = result as? [String: Any], error == nil else {
        print("Failed to make facebook graph request")
        return
      }
      print("\(result)")
      
      guard let userName = result["name"] as? String,
            let email = result["email"] as? String else {
        print("Failed to get email and name from FB")
        return
      }
      let nameComponents = userName.components(separatedBy: " ")
      guard nameComponents.count == 2 else {
        return
      }
      let firstName = nameComponents[0]
      let lastName = nameComponents[1]
      DatabaseManager.shared.userExists(with: email) { exists in
        if !exists {
          DatabaseManager.shared.insertUser(with: ChatAppUser(firstName: firstName, lastName: lastName, emailAdress: email))
        }
      }
      let credential = FacebookAuthProvider.credential(withAccessToken: token)
      FirebaseAuth.Auth.auth().signIn(with: credential) { [weak self] authResult, error in
        guard let strongSelf = self else {
          return
        }
        guard authResult != nil, error == nil else {
          if let error = error {
            print("Facebook credintial login failed, MFA may be needed - \(error)")
          }
          return
        }
        print("Login success")
        strongSelf.navigationController?.dismiss(animated: true)
      }
    }
  }
}
