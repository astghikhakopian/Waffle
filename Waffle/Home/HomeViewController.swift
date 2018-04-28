//
//  LoggedInViewController.swift
//  Waffle
//
//  Created by Astghik Hakopian on 4/12/18.
//

import UIKit
import Firebase

class HomeViewController: UIViewController {
    
    // MARK: - Properties
    
    @IBOutlet weak var imageOfUser: UIImageView!
    @IBOutlet weak var usernameLabel: UILabel!
    @IBOutlet weak var usernameTextField: UITextField!
    @IBOutlet weak var nameStackView: UIStackView!
    
    // MARK: - Actions
    
    @IBAction func editFunction(_ sender: Any) {
        
        usernameLabel.isHidden = true
        nameStackView.isHidden = false
        nameStackView.alpha = 1
    }
    
    @IBAction func editEmail(_ sender: Any) {
        
        let id = Auth.auth().currentUser?.uid
        Database.database().reference().child("users").child(id!).observeSingleEvent(of: .value, with: {(snapshot) in
            if let dictionary = snapshot.value as? [String: Any] {
                let email = (dictionary["email"] as! String)
                let title = "Do you want to change your Email?"
                let message = "Your current email adress is \(email)"
                let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
                alertController.addTextField { (textField) in
                    textField.placeholder = "Enter new email"}
                let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
                let okayAction = UIAlertAction(title: "Change", style: .default, handler: {action in
                    let id = Auth.auth().currentUser?.uid
                    let currentUser = Database.database().reference().child("users").child(id!)
                    currentUser.child("email").setValue(alertController.textFields![0].text)
                })
                alertController.addAction(cancelAction)
                alertController.addAction(okayAction)
                self.present(alertController, animated: true, completion: nil)
            }
        })
    }
   
    @IBAction func editPhoto(_ sender: Any) {
        /*if imageOfUser.image == nil {
            let imagePicker = UIImagePickerController()
            //imagePicker.delegate = self
            imagePicker.sourceType = .photoLibrary
            present(imagePicker, animated: true, completion: nil)
        }*/
    }
    
    @IBAction func saveNewUsername(_ sender: Any) {
        
        if usernameTextField.text == "" {
            nameStackView.isHidden = true
            usernameLabel.isHidden = false
        }
        else {
            let id = Auth.auth().currentUser?.uid
            let currentUser = Database.database().reference().child("users").child(id!)
            currentUser.child("name").setValue(usernameTextField.text)
            usernameLabel.text = usernameTextField.text
            nameStackView.isHidden = true
            usernameLabel.isHidden = false
            
        }
    }
    
    @IBAction func logOut() {
        
        if (try? Auth.auth().signOut()) != nil {
            if let viewController = self.storyboard?.instantiateViewController(withIdentifier: "loginVC") {
                UIApplication.shared.keyWindow?.rootViewController = viewController
                self.dismiss(animated: true, completion: nil)
                UserDefaults.standard.set(false, forKey: "isLoggedIn")
            }
        }
    }
    
    @IBAction func editPassword(_ sender: Any) {
        
        let id = Auth.auth().currentUser?.uid
        Database.database().reference().child("users").child(id!).observeSingleEvent(of: .value, with: {(snapshot) in
            if let dictionary = snapshot.value as? [String: Any] {
                if let email = (dictionary["email"] as? String) {
                    let actionCodeSettings = ActionCodeSettings()
                    actionCodeSettings.setIOSBundleID(Bundle.main.bundleIdentifier!)
                    
                    Auth.auth().sendPasswordReset(withEmail: email, actionCodeSettings: actionCodeSettings) { (error) in
                        if let error = error {
                            self.showAlert(title: "Reset Error", message: error.localizedDescription)
                        } else {
                            self.showAlert(title: "Success", message: "Please, check your email for reseting your password.")
                        }
                    }
                }
            }
        })
    }
    
    // MARK: - Lifecycle Methods
    
    private func showAlert(title: String, message: String) {
        
        let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
        let okayAction = UIAlertAction(title: "OK", style: .cancel, handler: nil)
        alertController.addAction(okayAction)
        self.present(alertController, animated: true, completion: nil)
    }
    
    override func viewDidLoad() {
        
        super.viewDidLoad()
        let id = Auth.auth().currentUser?.uid
        Database.database().reference().child("users").child(id!).observeSingleEvent(of: .value, with: {(snapshot) in
            if let dictionary = snapshot.value as? [String: Any] {
                self.usernameLabel.text = (dictionary["name"] as! String)
                self.usernameTextField.text = (dictionary["name"] as! String)
                if (dictionary["photoUrl"] as! String) != "" {
                    let theProfileImageURL = URL(string:(dictionary["photoUrl"]as! String))
                    do {
                        let imageData = try Data(contentsOf: theProfileImageURL as! URL)
                        self.imageOfUser.image = UIImage(data: imageData)
                    } catch {
                        print("Unable to load data: \(error)")
                    }
                } else {
                    self.imageOfUser.image = UIImage(named: "defaultProfile")
                }
                }
            })
        }
}

