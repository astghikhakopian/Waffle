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
    
    // MARK: - Properties
    
    
    @IBOutlet weak var containerViewTop: NSLayoutConstraint!
    @IBOutlet weak var logoVerticalCentre: NSLayoutConstraint!
    @IBOutlet weak var logoHeight: NSLayoutConstraint!
    @IBOutlet weak var logoWidth: NSLayoutConstraint!
    @IBOutlet weak var logoTop: NSLayoutConstraint!
    @IBOutlet weak var containerView: UIStackView!
    @IBOutlet weak var emailField: UITextField!
    @IBOutlet weak var passwordField: UITextField!
    @IBOutlet weak var labelOfWaffle: UILabel!
    @IBOutlet weak var imageViewTop: NSLayoutConstraint!
    

    // MARK: - Lifecycle Methods
    
    override func viewDidLoad() {
        super.viewDidLoad()
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            UIView.animate(withDuration: 0.6, delay: 0.0, options: .curveEaseOut, animations: {
                self.labelOfWaffle.text = ""
                self.logoHeight.constant = 150
                self.logoWidth.constant = 100
                self.logoTop.constant = self.containerViewTop.constant - 40
                self.logoVerticalCentre?.isActive = false
                self.view.layoutIfNeeded()
            }, completion: { (_) in
            })
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2, execute: {
                UIView.animate(withDuration: 0.2, animations: {
                    self.containerView.isHidden = false
                    self.emailField.delegate = self
                    self.passwordField.delegate = self
                })
            })
        }
        
    }
    deinit {
        print("LoginViewController deallocated")
        
    }
    
    // MARK: - Actions
    
    @IBAction func fbLoginButtonAction(_ sender: Any) {
        let fbLoginManager = FBSDKLoginManager()
        fbLoginManager.logIn(withReadPermissions: ["email"], from: self) { (result, error) -> Void in
            if (error == nil) && (result?.isCancelled)! {
                    return
            } else {
                let credential = FacebookAuthProvider.credential(withAccessToken: FBSDKAccessToken.current().tokenString)
                self.performLogin(with: credential, error: error, accessToken: FBSDKAccessToken.current().tokenString)
            }
        }
    }
    
    @IBAction func googleLoginButtonAction(_ sender: Any) {
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
                    UserDefaults.standard.set(user?.uid, forKey: "currentUserId")
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
        if error == nil {
            let credential = GoogleAuthProvider.credential(withIDToken: user.authentication.idToken, accessToken: user.authentication.accessToken)
            performLogin(with: credential, error: error, accessToken: user.authentication.accessToken)
        } else {
            return
        }
    }
    
    func sign(_ signIn: GIDSignIn!, didDisconnectWith user: GIDGoogleUser!,
              withError error: Error!) {
        return
    }
    
    // MARK: - UITextFieldDelegate
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
   
    // MARK: - Private Methods
    
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
                if let user = user {
                    //ete ka dbum
                    let databaseRef = Database.database().reference()
                    databaseRef.child("users").observeSingleEvent(of: DataEventType.value, with: { (snapshot) in
                        
                        if snapshot.hasChild(user.uid) {
                            Auth.auth().signIn(with: credential, completion: { (user, error) in })
                        } else {
                             let photoUrlString = (user.photoURL?.absoluteString)! + "?type=large"
                            self.addUserToDatabase(id: user.uid, dispayName: user.displayName ?? "", photoUrl: URL(string: photoUrlString), email: user.email, phoneNumber: user.phoneNumber)
                        }
                    })
                    UserDefaults.standard.set(true, forKey: "isLoggedIn")
                    UserDefaults.standard.set(user.uid, forKey: "currentUserId")
                    self.moveToVC(withIdentifier: "loggedInVC")
                }
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
    
    private func addUserToDatabase(id: String, dispayName: String, photoUrl: URL?, email: String?, phoneNumber: String?) {
        var photo: String?
        if let photoUrl = photoUrl {
            photo = String(describing: photoUrl)
        }
        let newUser = Database.database().reference().child("users").child(id)
        newUser.setValue(["id": id, "name": dispayName, "photoUrl": photo ?? "", "email": email ?? "", "phone number": phoneNumber ?? ""])
    }
}
