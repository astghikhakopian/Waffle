//
//  ViewController.swift
//  Waffle
//
//  Created by Astghik Hakopian on 4/11/18.
//

import UIKit
import FBSDKLoginKit
import Firebase

class LoginViewController: UIViewController {
    
    // MARK: - Lifecycle Methods
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    // MARK: - Outlets
    
    @IBAction func fbLoginButton(_ sender: Any) {
        let fbLoginManager = FBSDKLoginManager()
        fbLoginManager.logIn(withReadPermissions: ["email"], from: self) { (result, error) -> Void in
            if let error = error {
                print("Failed to login: \(error.localizedDescription)")
                return
            }
            
            //let fbloginresult: FBSDKLoginManagerLoginResult = result!
            if (result?.isCancelled)! {
                print("Login cancelled")
                return
            }
            guard let accessToken = FBSDKAccessToken.current() else {
                print("Failed to get access token")
                return
            }
            
            let credential = FacebookAuthProvider.credential(withAccessToken: accessToken.tokenString)
            
            // Perform login by calling Firebase APIs
            Auth.auth().signIn(with: credential, completion: { (user, error) in
                if let error = error {
                    print("Login error: \(error.localizedDescription)")
                    let alertController = UIAlertController(title: "Login Error", message: error.localizedDescription, preferredStyle: .alert)
                    let okayAction = UIAlertAction(title: "OK", style: .cancel, handler: nil)
                    alertController.addAction(okayAction)
                    self.present(alertController, animated: true, completion: nil)
                    
                    return
                }
                
                if let viewController = self.storyboard?.instantiateViewController(withIdentifier: "loggedInVC") {
                    UIApplication.shared.keyWindow?.rootViewController = viewController
                    self.dismiss(animated: true, completion: nil)
                }
                
            })
            
            //            if(fbloginresult.grantedPermissions.contains("email")) {
            //                let parameters = ["fields": "first_name, last_name, email, picture.type(large), birthday, gender, hometown"]
            //
            //                FBSDKGraphRequest(graphPath: "me", parameters: parameters).start { (connection, result, error) in
            //                    if let error = error {
            //                        print(error)
            //                        return
            //                    }
            //                    let userInfoJSON = result as! [String: Any]
            //                    self.fetchProfile(userInfoJSON: userInfoJSON)
            //
            //                }
            //            }
        }
    }
    
    
    // MARK: - Private Methods
    
    //    private func fetchProfile(userInfoJSON: [String: Any]) {
    //        let firstname = userInfoJSON["first_name"] as? String ?? ""
    //        let lastname = userInfoJSON["last_name"] as? String ?? ""
    //        let userEmail =  userInfoJSON["email"] as? String ?? ""
    //
    //        let pictureData = userInfoJSON["picture"] as? [String: Any] ?? ["data": ""]
    //        let pictureInfo = pictureData["data"] as? [String: Any] ?? ["url": ""]
    //        let userPictureURL = pictureInfo["url"] as? String ?? ""
    //
    //        let token = FBSDKAccessToken.current().tokenString!
    //
    //        print("--- firstname: \(firstname)")
    //        print("--- lastname: \(lastname)")
    //        print("--- email: \(userEmail)")
    //        print("--- picture url: \(userPictureURL)")
    //        print("--- access token: \(token)")
    //    }
}
