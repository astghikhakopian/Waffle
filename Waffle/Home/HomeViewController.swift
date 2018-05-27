//
//  LoggedInViewController.swift
//  Waffle
//
//  Created by Astghik Hakopian on 4/12/18.
//

import UIKit
import Firebase
import MobileCoreServices

class HomeViewController: UIViewController {
    
    // MARK: - Properties
    
    @IBOutlet weak var imageOfUser: UIImageView!
    @IBOutlet weak var usernameLabel: UILabel!
    @IBOutlet weak var usernameTextField: UITextField!
    @IBOutlet weak var nameStackView: UIStackView!
    @IBOutlet weak var spinner: UIActivityIndicatorView!
    let dispatchQueue = DispatchQueue(label: "Dispatch Queue", attributes: [], target: nil)
    
    // MARK: - Lifecycle Methods
    
    override func viewDidLoad() {
        super.viewDidLoad()
        if (imageOfUser.image == nil) {
            spinner.startAnimating()
            addNavViewBarImage()
            DispatchQueue.global(qos: .userInteractive).asyncAfter(deadline: .now() + 1, execute:  {
                 DispatchQueue.global(qos: .userInteractive).async {
                    let id = Auth.auth().currentUser?.uid
                    Database.database().reference().child("users").child(id!).observeSingleEvent(of: .value, with: {(snapshot) in
                        if let dictionary = snapshot.value as? [String: Any] {
                            DispatchQueue.main.async {
                                self.usernameLabel.text = (dictionary["name"] as! String)
                                self.usernameTextField.text = (dictionary["name"] as! String)
                            }
                            if (dictionary["photoUrl"] as! String) != "" {
                                let theProfileImageURL = URL(string:(dictionary["photoUrl"]as! String))
                                do {
                                    let imageData = try Data(contentsOf: theProfileImageURL!)
                                    DispatchQueue.main.async {self.imageOfUser.image = UIImage(data: imageData)
                                    }
                                }catch {
                                    print("Unable to load data: \(error)")
                                }
                            } else {
                                DispatchQueue.main.async {self.imageOfUser.image = UIImage(named: "defaultProfile")
                                }
                            }
                        }
                    })
                }
                DispatchQueue.main.async {
                    self.spinner.stopAnimating()
                    self.spinner.isHidden = true
                    self.imageOfUser.isHidden = false
                }
            })
        }
    }
    
    // MARK: - Actions
    
    @IBAction func editUsernameAction(_ sender: Any) {
        usernameLabel.isHidden = true
        nameStackView.isHidden = false
        nameStackView.alpha = 1
    }
    
    @IBAction func editPhoneNumberAction(_ sender: Any) {
        let id = Auth.auth().currentUser?.uid
        Database.database().reference().child("users").child(id!).observeSingleEvent(of: .value, with: {(snapshot) in
            if let dictionary = snapshot.value as? [String: Any] {
                let phoneNumber = (dictionary["phone number"] as! String)
                let title = "Do you want to change your Phone Number?"
                let message = "Your current phone number is \(phoneNumber)"
                let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
                alertController.addTextField { (textField) in
                    textField.placeholder = "Enter new phone number"}
                let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
                let okayAction = UIAlertAction(title: "Change", style: .default, handler: {action in
                    let id = Auth.auth().currentUser?.uid
                    let currentUser = Database.database().reference().child("users").child(id!)
                    currentUser.child("phone number").setValue(alertController.textFields![0].text)
                })
                alertController.addAction(cancelAction)
                alertController.addAction(okayAction)
                self.present(alertController, animated: true, completion: nil)
            }
        })
    }
    
    @IBAction func editEmailAction(_ sender: Any) {
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
    
    @IBAction func editPhotoAction(_ sender: Any) {
        getMedia(kUTTypeImage)
    }
    
    @IBAction func saveNewUsername(_ sender: Any) {
        if usernameTextField.text == "" {
            nameStackView.isHidden = true
            usernameLabel.isHidden = false
            usernameTextField.resignFirstResponder()
        } else {
            let id = Auth.auth().currentUser?.uid
            let currentUser = Database.database().reference().child("users").child(id!)
            currentUser.child("name").setValue(usernameTextField.text)
            usernameLabel.text = usernameTextField.text
            nameStackView.isHidden = true
            usernameLabel.isHidden = false
            usernameTextField.resignFirstResponder()
            
        }
    }
    
    @IBAction func logOut() {
        
        let alertController = UIAlertController(title: "Do you really want to log out?", message: nil, preferredStyle: .alert)
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
        let okayAction = UIAlertAction(title:"Yes", style: .default, handler: logOutHandler)
        alertController.addAction(cancelAction)
        alertController.addAction(okayAction)
        self.present(alertController, animated: true, completion: nil)
            }
    

    func logOutHandler(alert: UIAlertAction!) {
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
    
    // MARK: - Private Methods
    
    private func showAlert(title: String, message: String) {
        let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
        let okayAction = UIAlertAction(title: "OK", style: .cancel, handler: nil)
        alertController.addAction(okayAction)
        self.present(alertController, animated: true, completion: nil)
    }
    
    private func getMedia(_ type: CFString) {
        let mediaPicker = UIImagePickerController()
        mediaPicker.delegate = self
        mediaPicker.mediaTypes = [type as String]
        self.present(mediaPicker, animated: true, completion: nil)
    }
    
    private func addNavViewBarImage() {
        let navController = self.navigationController
        let logo = UIImage(named: "logo.png")
        let imageView = UIImageView(image:logo)
        self.navigationItem.titleView = imageView
        let bannerWidth = navController?.navigationBar.frame.size.width
        let bannerHeight = navController?.navigationBar.frame.size.height
        imageView.frame = CGRect(x: 0, y: 0, width: bannerWidth!, height:bannerHeight!)
        imageView.contentMode = .scaleAspectFit
        self.navigationItem.titleView = imageView
    }
}


//MARK: - Delegation below

extension HomeViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {

    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
        
        if let image = info[UIImagePickerControllerOriginalImage] as? UIImage {
            imageOfUser.image = image
            let filePath = "\(Auth.auth().currentUser!.uid)/\(Date.timeIntervalSinceReferenceDate)"
            Storage.storage().reference().child(filePath)
            let data = UIImageJPEGRepresentation(image, 0.5)
            let metadata = StorageMetadata()
            metadata.contentType = "image/jpg"
            Storage.storage().reference().child(filePath).putData(data!, metadata: metadata) { (metadata, error) in
                if error != nil {
                    print(error!.localizedDescription)
                    return
                }
                StorageReference().child(filePath).downloadURL(completion: { (url, error) in
                    if error == nil {
                        if let downloadString = url {
                            let downloadURL = downloadString.absoluteString
                        Database.database().reference().child("users").child(Auth.auth().currentUser!.uid).child("photoUrl").setValue(downloadURL)
                        }
                    } else {
                        print("Something went wrong!!")
                    }
                })
            }
            self.dismiss(animated: true, completion: nil)
        }
    }
}







