//
//  ViewController.swift
//  Waffle
//
//  Created by Astghik Hakopian on 4/11/18.
//

import UIKit
import FBSDKLoginKit
import GoogleSignIn
import Firebase
import FirebaseDatabase

class LoginViewController: UIViewController, GIDSignInDelegate, GIDSignInUIDelegate, UITextFieldDelegate {
    
    @IBOutlet weak var emailField: UITextField!
    @IBOutlet weak var passwordField: UITextField!
    
    // MARK: - Lifecycle Methods
    
    override func viewDidLoad() {
        super.viewDidLoad()
        emailField.delegate = self
        passwordField.delegate = self
    }
    
    
    // MARK: - Outlets
    
    @IBAction func fbLoginButton(_ sender: Any) {
        let fbLoginManager = FBSDKLoginManager()
        fbLoginManager.logIn(withReadPermissions: ["email"], from: self) { (result, error) -> Void in
            let credential = FacebookAuthProvider.credential(withAccessToken: FBSDKAccessToken.current().tokenString)
            self.performLogin(with: credential, error: error, accessToken: FBSDKAccessToken.current().tokenString)
        }
    }
    
    @IBAction func googleLoginButton(_ sender: Any) {
        GIDSignIn.sharedInstance().delegate = self
        GIDSignIn.sharedInstance().uiDelegate = self
        GIDSignIn.sharedInstance().signIn()
    }
    
    @IBAction func signIn() {
        if let email = emailField.text, let password = passwordField.text {
            Auth.auth().signIn(withEmail: email, password: password) { (user, error) in
                if let error = error {
                    self.showAlert(title: "Login Error", message: error.localizedDescription)
                } else {
                    // TODO: - Logged In user becomes current user
                    UserDefaults.standard.set(true, forKey: "isLoggedIn")
                    self.moveToVC(withIdentifier: "loggedInVC")
                }
            }
        }
    }
    
    @IBAction func forgotPassword() {
        if let email = emailField.text {
            let actionCodeSettings = ActionCodeSettings()
            actionCodeSettings.setIOSBundleID(Bundle.main.bundleIdentifier!)
            
            Auth.auth().sendPasswordReset(withEmail: email, actionCodeSettings: actionCodeSettings) { (error) in
                if let error = error {
                    self.showAlert(title: "Reset Error", message: error.localizedDescription)
                } else {
                    self.showAlert(title: "Success", message: "Please, check your email for reseting your password.")
                    self.emailField.text = nil
                }
            }
        }
    }
    
    @IBAction func moveToSignUp() {
        moveToVC(withIdentifier: "SignUpVC")
    }
    
    // MARK: - GIDSignInDelegate
    
    func sign(_ signIn: GIDSignIn!, didSignInFor user: GIDGoogleUser!, withError error: Error!) {
        let credential = GoogleAuthProvider.credential(withIDToken: user.authentication.idToken, accessToken: user.authentication.accessToken)
        performLogin(with: credential, error: error, accessToken: user.authentication.accessToken)
    }

    
    // MARK: - Private Methods
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        self.view.endEditing(true)
    }
    
    private func performLogin(with credential: AuthCredential, error: Error?, accessToken: String?) {
        if let error = error {
            print("Login error: \(error.localizedDescription)")
            return
        }
        guard accessToken != nil else {
            print("Failed to get access token")
            return
        }
        
        Auth.auth().signIn(with: credential) { (user, error) in
            if let error = error {
                self.showAlert(title: "Login Error", message: error.localizedDescription)
            } else {
                let newUser = Database.database().reference().child("users").child(user!.uid)
                newUser.setValue(["displayname": "\(user!.displayName!)", "id": "\(user!.uid)", "photoURL": "\(user!.photoURL!)"])
                
                UserDefaults.standard.set(true, forKey: "isLoggedIn")
                self.moveToVC(withIdentifier: "loggedInVC")
            }
        }
    }
    
    private func showAlert(title: String, message: String) {
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
