//
//  LoggedInViewController.swift
//  Waffle
//
//  Created by Astghik Hakopian on 4/12/18.
//

import UIKit
import Firebase

class LoggedInViewController: UIViewController {
    
    // MARK: - Properties
    
    @IBOutlet weak var usernameLabel: UILabel!
    
    
    // MARK: - Lifecycle Methods
    
    override func viewDidLoad() {
        super.viewDidLoad()
     
        if let currentUser = Auth.auth().currentUser {
            usernameLabel.text = currentUser.displayName
        }
    }
    
    
    // MARK: - Actions
    
    @IBAction func logOut() {
        if (try? Auth.auth().signOut()) != nil {
            if let viewController = self.storyboard?.instantiateViewController(withIdentifier: "loginVC") {
                UIApplication.shared.keyWindow?.rootViewController = viewController
                self.dismiss(animated: true, completion: nil)
                UserDefaults.standard.set(false, forKey: "isLoggedIn")
            }
        }
    }
}
