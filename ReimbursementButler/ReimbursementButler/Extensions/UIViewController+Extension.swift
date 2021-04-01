//
//  ViewController.swift
//

import UIKit
import Firebase
import FirebaseDatabase
import FirebaseAuth
import FirebaseStorage

extension UIViewController {
    func showAlert(alertTitle : String, alertMessage : String) {
        let alert = UIAlertController(title: alertTitle, message: alertMessage, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "ok".localized(), style: .default, handler: nil))
        self.present(alert, animated: true)
    }

    func showAlert(alertTitle:String) {
        showAlert(alertTitle: alertTitle, alertMessage: "")
    }
}

