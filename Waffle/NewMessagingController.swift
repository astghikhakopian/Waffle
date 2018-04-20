//
//  NewMessagingController.swift
//  Waffle
//
//  Created by Sierra os on 4/19/18.
//

import UIKit
import Firebase
class NewMessagingController: UITableViewController {

    let cellId = "cellId"
    var users = [User]()
    override func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.leftBarButtonItem = UIBarButtonItem(title: "Cancel", style: .plain, target: self, action: #selector(handleCancel))
        
       fetchUser()
    }
    
    func fetchUser() {
        Database.database().reference().child("users").observe(.childAdded, with: {(snapshot) in
            if let dictionary = snapshot.value as? [String: Any] {
                let user = User()
                //user.setValuesForKeys(dictionary)
                user.name = (dictionary["name"] as! String)
                user.email = (dictionary["email"] as! String)
                self.users.append(user)
                 DispatchQueue.main.async {self.tableView.reloadData()}
            }
        }, withCancel: nil)
    }
    @objc func handleCancel() {
        dismiss(animated: true, completion: nil)
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return users.count
    }
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        
        let cell = UITableViewCell(style: .subtitle, reuseIdentifier: cellId)
        let user = users[indexPath.row]
        cell.textLabel?.text = user.name
        return cell
    }

}
