//
//  AllUsersViewController.swift
//  Waffle
//
//  Created by Astghik Hakopian on 4/22/18.
//

import UIKit
import Firebase

class AllUsersViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {
    
    @IBOutlet weak var tableView: UITableView!
    
    var users: [User] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.register(UINib(nibName: "UsersTableViewCell", bundle: nil), forCellReuseIdentifier: "UsersTableViewCell")
        
        fetchUsers()
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return users.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "UsersTableViewCell") as! UsersTableViewCell
        
        cell.nameLabel.text = users[indexPath.row].name
        cell.emailLabel.text = users[indexPath.row].email
        
        let imageUrl = URL(string: users[indexPath.row].photoURL!)
        if let theProfileImageUrl = imageUrl {
            do {
                let imageData = try Data(contentsOf: theProfileImageUrl as URL)
                cell.imageVIew.image = UIImage(data: imageData)
                cell.imageVIew.layer.borderWidth=1.0
                cell.imageVIew.layer.borderColor = UIColor.white.cgColor
                cell.imageVIew.layer.masksToBounds = false
                cell.imageVIew.layer.cornerRadius = cell.imageVIew.frame.size.height/2
                cell.imageVIew.clipsToBounds = true
            } catch {
                print("Unable to load data: \(error)")
            }
        } else {
            cell.imageVIew.layer.borderWidth=1.0
            cell.imageVIew.layer.masksToBounds = false
            cell.imageVIew.layer.cornerRadius = cell.imageVIew.frame.size.height/2
            cell.imageVIew.layer.borderColor = UIColor.white.cgColor
            cell.imageVIew.clipsToBounds = true
            cell.imageVIew.image = UIImage(named: "defaultProfile")
        }
        
        let tap = ClickListener(target: self, action: #selector(self.handleTap(gestureRecognizer:)))
        tap.userId = users[indexPath.row].id
        cell.addGestureRecognizer(tap)
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 80.0
    }
    
    
    // MARK: - Private Methods
    
    private func fetchUsers() {
        Database.database().reference().child("users").observe(.childAdded, with: {(snapshot) in
            if let dictionary = snapshot.value as? [String: Any] {
                var user = User()
                user.name = (dictionary["name"] as! String)
                user.email = (dictionary["email"] as! String)
                user.id = (dictionary["id"] as! String)
                user.photoURL = (dictionary["photoUrl"] as! String)
                self.users.append(user)
                DispatchQueue.main.async {
                    self.tableView.reloadData()
                }
            }
        }, withCancel: nil)
    }
    
    
    
    @objc private func handleTap(gestureRecognizer: ClickListener) {
        if let chatVC = storyboard?.instantiateViewController(withIdentifier: "chatVC") as? ChatVIewController {
            
            chatVC.friendId = gestureRecognizer.userId
            
            present(chatVC, animated: true)
        }
    }
}

class ClickListener : UITapGestureRecognizer{
    var userId: String!
}


