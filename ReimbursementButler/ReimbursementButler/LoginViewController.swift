//
//  LoginViewController.swift
//

import AVFoundation
import UIKit
import Firebase
import FirebaseDatabase

class LoginViewController: UIViewController {

    let loginButton : UIButton = {
        let button = UIButton()
        button.backgroundColor = .xpnsAppGreen
        button.tintColor = .xpnsAppGreen
        button.layer.cornerRadius = 25
        button.setTitle("login".localized(),for: .normal)
        button.translatesAutoresizingMaskIntoConstraints = false

        return button
    }()

    let signinButton : UIButton = {
        let button = UIButton()
        button.backgroundColor = .xpnsAppGreen
        button.tintColor = .xpnsAppBlue
        button.layer.cornerRadius = 25
        button.setTitle("signin".localized(),for: .normal)
        button.translatesAutoresizingMaskIntoConstraints = false

        return button
    }()

    let emailTextField : UITextField = {
        let textField = UITextField()
        textField.keyboardType = .emailAddress
        textField.translatesAutoresizingMaskIntoConstraints = false
        textField.placeholder = "email".localized()
        textField.textColor = .xpnsAppBlue
        textField.borderStyle = .roundedRect
        textField.backgroundColor = .lightGray
        return textField
    }()

    let passwordTextField : UITextField = {
        let textField = UITextField()
        textField.keyboardType = .default
        textField.translatesAutoresizingMaskIntoConstraints = false
        textField.placeholder = "password".localized()
        textField.textColor = .xpnsAppBlue
        textField.borderStyle = .roundedRect
        textField.backgroundColor = .lightGray
        return textField
    }()

    func setupView(){
        view.backgroundColor = .gray
        view.addSubview(emailTextField)
        view.addSubview(passwordTextField)
        view.addSubview(loginButton)
        view.addSubview(signinButton)


        NSLayoutConstraint.activate([
            emailTextField.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 10),
            emailTextField.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 10),
            emailTextField.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -10),
            emailTextField.heightAnchor.constraint(equalToConstant: 50),

            passwordTextField.topAnchor.constraint(equalTo: emailTextField.bottomAnchor, constant: 10),
            passwordTextField.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 10),
            passwordTextField.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -10),
            passwordTextField.heightAnchor.constraint(equalToConstant: 50),

            loginButton.topAnchor.constraint(equalTo: passwordTextField.bottomAnchor, constant: 10),
            loginButton.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 10),
            loginButton.widthAnchor.constraint(equalToConstant: 120),
            loginButton.heightAnchor.constraint(equalToConstant: 50),

            signinButton.topAnchor.constraint(equalTo: passwordTextField.bottomAnchor, constant: 10),
            signinButton.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -10),
            signinButton.widthAnchor.constraint(equalToConstant: 120),
            signinButton.heightAnchor.constraint(equalToConstant: 50),
        ])

        loginButton.addTarget(self, action: #selector(doLogin(_:)), for: .touchUpInside)
        signinButton.addTarget(self, action: #selector(doSignin(_:)), for: .touchUpInside)

    }

    override func viewDidLoad() {
        super.viewDidLoad()
        initializeHideKeyboard()

        emailTextField.delegate = self
        passwordTextField.delegate = self
        setupView()

    }
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        if let emailText = self.emailTextField.text, emailText.isEmpty{
            emailTextField.becomeFirstResponder()
        }
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        emailTextField.resignFirstResponder()
        passwordTextField.resignFirstResponder()
    }

    @IBAction func doSignin(_ sender: Any) {
        guard let emailText = emailTextField.text , emailText.count > 0  else {
            self.showAlert(alertTitle: "pleaseenteremail".localized())
            return
        }

        guard let passwordText = passwordTextField.text , passwordText.count > 0  else {
            self.showAlert(alertTitle: "pleaseenterpassword".localized())
            return
        }

        Auth.auth().createUser(withEmail: emailText, password: passwordText) { authResult, error in
            if let error = error {
                self.showAlert(alertTitle: "createaccounterror".localized(), alertMessage: error.localizedDescription)
            } else {
                self.changeRootViewController()
            }
        }
    }

    @IBAction func doLogin(_ sender: Any) {
        guard let emailText = emailTextField.text , emailText.count > 0  else {
            self.showAlert(alertTitle: "pleaseenteremail".localized())
            return
        }

        guard let passwordText = passwordTextField.text , passwordText.count > 0  else {
            self.showAlert(alertTitle: "pleaseenterpassword".localized())
            return
        }

        Auth.auth().signIn(withEmail: emailText, password: passwordText) { authResult, error in
            if let error = error {
                self.showAlert(alertTitle: "loginerror", alertMessage: error.localizedDescription)
            } else {
                self.changeRootViewController()
            }
        }
    }

    func changeRootViewController() {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let mainTabBarController = storyboard.instantiateViewController(identifier: "MainTabBarController")

        // This is to get the SceneDelegate object from the view controller
        // and then we call the change root view controller function to change to main tab bar
        (UIApplication.shared.connectedScenes.first?.delegate as? SceneDelegate)?.changeRootViewController(mainTabBarController)
    }
}

extension LoginViewController {
    func initializeHideKeyboard() {
        let tap: UITapGestureRecognizer = UITapGestureRecognizer(
        target: self,
        action: #selector(dismissKeyboard))
        view.addGestureRecognizer(tap)
    }
    @objc func dismissKeyboard(){
        view.endEditing(true)
    }

}

extension LoginViewController: UITextFieldDelegate {

    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        switch textField {
        case emailTextField:
            emailTextField.resignFirstResponder()
            passwordTextField.becomeFirstResponder()
            break
        case passwordTextField:
            passwordTextField.resignFirstResponder()
            break
        default:
            break
        }
        return true
    }
}
