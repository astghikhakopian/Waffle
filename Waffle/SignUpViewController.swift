//
//  SignUpViewController.swift
//  Waffle
//
//  Created by Astghik Hakopian on 4/15/18.
//

import UIKit
import Firebase
import FirebaseDatabase
class SignUpViewController: UIViewController, UITextFieldDelegate {
    
    // MARK: - Properties

    @IBOutlet weak var usernameField: UITextField!
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
        
        if let username = usernameField.text, let email = emailField.text, let pass = passwordField.text, let repeatpass = repeatPasswordField.text {
            if pass == repeatpass {
                
                Auth.auth().createUser (withEmail: email, password: pass) { (user, error) in
                    if let error = error {
                        self.showAlert(title: "Sign Up Error", message: error.localizedDescription)
                    } else {
                        self.moveToVC(withIdentifier: "loggedInVC")
                        let ref = Database.database().reference()
                        let usersReference = ref.child("users")
                        //print(usersReference.description())
                        let uid = user?.uid
                        let newUserReference = usersReference.child(uid!)
                        newUserReference.setValue(["Username": username, "Email": email])
                        
                        
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
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
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
