//
//  AccountViewController.swift
//

import AVFoundation
import UIKit
import Firebase
import FirebaseDatabase
class AccountViewController: UIViewController {

    let logoutButton : UIButton = {
        let button = UIButton()
        button.backgroundColor = .xpnsAppRed
        button.tintColor = .xpnsAppBlue
        button.layer.cornerRadius = 25
        button.setTitle("logout".localized(),for: .normal)
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
        textField.isUserInteractionEnabled = false
        return textField
    }()

    func changeRootViewController() {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let loginNavController = storyboard.instantiateViewController(
            identifier: "LoginNavigationController")

        // This is to get the SceneDelegate object from the view controller
        // and then we call the change root view controller function to change to login contoller
        (UIApplication.shared.connectedScenes.first?.delegate as? SceneDelegate)?.changeRootViewController(loginNavController)
    }

    func setupView(){
        view.backgroundColor = .gray
        view.addSubview(logoutButton)
        view.addSubview(emailTextField)

        NSLayoutConstraint.activate([
            logoutButton.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 10),
            logoutButton.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -10),
            logoutButton.widthAnchor.constraint(equalToConstant: 120),
            logoutButton.heightAnchor.constraint(equalToConstant: 50),

            emailTextField.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 80),
            emailTextField.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 10),
            emailTextField.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -10),
            emailTextField.heightAnchor.constraint(equalToConstant: 50),
        ])
        logoutButton.addTarget(self, action: #selector(logoutButtonClicked(_:)), for: .touchUpInside)
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        guard let uid = Auth.auth().currentUser?.uid else {
            self.showAlert(alertTitle: "couldnotfindauthuser".localized(), alertMessage: "pleaseloginagain".localized())
            self.changeRootViewController()
            return
        }

        guard let email = Auth.auth().currentUser?.email else {
            self.showAlert(alertTitle: "couldnotreaduseremail".localized(), alertMessage: "pleaseloginagain".localized())
            self.changeRootViewController()
            return
        }

        emailTextField.text = email

        setupView()
    }

    @objc func logoutButtonClicked(_ sender: UIButton?){
        do {
            try Auth.auth().signOut()

            let storyboard = UIStoryboard(name: "Main", bundle: nil)
            let loginNavController = storyboard.instantiateViewController(
                identifier: "LoginNavigationController")

            // This is to get the SceneDelegate object from the view controller
            // and then we call the change root view controller function to change to login contoller
            (UIApplication.shared.connectedScenes.first?.delegate as? SceneDelegate)?.changeRootViewController(loginNavController)
        } catch  {
            self.showAlert(alertTitle: "logouterror".localized(), alertMessage: "logouterrordescription".localized())
        }
    }
}
