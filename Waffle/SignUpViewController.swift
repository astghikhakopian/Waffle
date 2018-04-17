//
//  SignUpViewController.swift
//  Waffle
//
//  Created by Astghik Hakopian on 4/15/18.
//

import UIKit
import Firebase

class SignUpViewController: UIViewController, UITextFieldDelegate {
    
    // MARK: - Properties

    @IBOutlet weak var emailField: UITextField!
    @IBOutlet weak var passwordField: UITextField!
    @IBOutlet weak var repeatPasswordField: UITextField!
    
    
    // MARK: - Lifecicle Methods
    
    override func viewDidLoad() {
        super.viewDidLoad()
        emailField.delegate = self
        passwordField.delegate = self
        repeatPasswordField.delegate = self
    }
    
    
    // MARK: - Actions
    
    @IBAction func signUp() {
        if let email = emailField.text, let pass = passwordField.text, let repeatpass = repeatPasswordField.text {
            if pass == repeatpass {
                Auth.auth().createUser(withEmail: email, password: pass) { (user, error) in
                    if let error = error {
                        self.showAlert(title: "Sign Up Error", message: error.localizedDescription)
                    } else {
                        self.moveToVC(withIdentifier: "loginVC")
                    }
                }
            } else {
                showAlert(title: "Sign Up Error", message: "Passwords are not the same.")
            }
        } else {
            showAlert(title: "Sign Up Error", message: "Please fill all fields")
        }
    }
    
    @IBAction func moveToLoginVC() {
        moveToVC(withIdentifier: "loginVC")
    }
    
    
    // MARK: - Private Methods
    
    func textFieldShouldReturn(textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        self.view.endEditing(true)
    }
    
    private func showAlert(title: String, message: String ) {
        let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
        let okayAction = UIAlertAction(title: "OK", style: .cancel, handler: nil)
        alertController.addAction(okayAction)
        self.present(alertController, animated: true, completion: nil)
    }
    
    private func moveToVC(withIdentifier identifier: String) {
        if let viewController = self.storyboard?.instantiateViewController(withIdentifier: identifier) {
            UIApplication.shared.keyWindow?.rootViewController = viewController
            self.dismiss(animated: true, completion: nil)
        }
    }
}
