//
//  ViewController.swift
//  Waffle
//
//  Created by Astghik Hakopian on 4/11/18.
//

import UIKit
import FBSDKLoginKit

class LoginViewController: UIViewController {
    
    // MARK: - Outlets
    
    // MARK: - Lifecycle Methods
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    
    // MARK: - Private Methods
    private func fetchProfile(userInfoJSON: [String: Any]) {
        let firstname = userInfoJSON["first_name"] as? String ?? ""
        let lastname = userInfoJSON["last_name"] as? String ?? ""
        let userEmail =  userInfoJSON["email"] as? String ?? ""
        
        let pictureData = userInfoJSON["picture"] as? [String: Any] ?? ["data": ""]
        let pictureInfo = pictureData["data"] as? [String: Any] ?? ["url": ""]
        let userPictureURL = pictureInfo["url"] as? String ?? ""
        
        let token = FBSDKAccessToken.current().tokenString!
        
        print("--- firstname: \(firstname)")
        print("--- lastname: \(lastname)")
        print("--- email: \(userEmail)")
        print("--- picture url: \(userPictureURL)")
        print("--- access token: \(token)")
    }
    
    //MARK: - Actions
    @IBAction func fbLoginButton(_ sender: Any) {
        let fbLoginManager : FBSDKLoginManager = FBSDKLoginManager()
        fbLoginManager.logIn(withReadPermissions: ["email"], from: self) { (result, error) -> Void in
            if error == nil {
                let fbloginresult: FBSDKLoginManagerLoginResult = result!
                if (result?.isCancelled)! {
                    return
                }
                if(fbloginresult.grantedPermissions.contains("email")) {
                    let parameters = ["fields": "first_name, last_name, email, picture.type(large), birthday, gender, hometown"]
                    
                    FBSDKGraphRequest(graphPath: "me", parameters: parameters).start { (connection, result, error) in
                        if let error = error {
                            print(error)
                            return
                        }
                        let userInfoJSON = result as! [String: Any]
                        self.fetchProfile(userInfoJSON: userInfoJSON)
                    }
                }
            }
        }
    }
}
