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

class LoginViewController: UIViewController, GIDSignInDelegate, GIDSignInUIDelegate {
    
    // MARK: - Lifecycle Methods
    
    override func viewDidLoad() {
        super.viewDidLoad()
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
    
    
    // MARK: - GIDSignInDelegate
    
    func sign(_ signIn: GIDSignIn!, didSignInFor user: GIDGoogleUser!, withError error: Error!) {
        let credential = GoogleAuthProvider.credential(withIDToken: user.authentication.idToken, accessToken: user.authentication.accessToken)
        performLogin(with: credential, error: error, accessToken: user.authentication.accessToken)
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
                print("Login error: \(error.localizedDescription)")
                let alertController = UIAlertController(title: "Login Error", message: error.localizedDescription, preferredStyle: .alert)
                let okayAction = UIAlertAction(title: "OK", style: .cancel, handler: nil)
                alertController.addAction(okayAction)
                self.present(alertController, animated: true, completion: nil)
            } else {
                // sagh normal a
                if let viewController = self.storyboard?.instantiateViewController(withIdentifier: "loggedInVC") {
                    UIApplication.shared.keyWindow?.rootViewController = viewController
                    self.dismiss(animated: true, completion: nil)
                }
            }
        }
    }
}
