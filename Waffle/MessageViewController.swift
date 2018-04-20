//
//  MessageViewController.swift
//  Waffle
//
//  Created by Sierra os on 4/19/18.
//

import UIKit
import Firebase

class MessageViewController:UIViewController{
    
    @IBOutlet weak var nameLabel: UILabel!
    @IBAction func handleNewMessage() {
        let newMessageController = NewMessagingController()
        let navController = UINavigationController(rootViewController: newMessageController)
        present(navController, animated: true, completion:nil)
    }
    
    @IBAction func logOutAction(_ sender: Any) {
        if (try? Auth.auth().signOut()) != nil {
            if let viewController = self.storyboard?.instantiateViewController(withIdentifier: "loginVC") {
                UIApplication.shared.keyWindow?.rootViewController = viewController
                self.dismiss(animated: true, completion: nil)
                UserDefaults.standard.set(false, forKey: "isLoggedIn")
            }
        }
    }
    
   
   
    override func viewDidLoad() {
        super.viewDidLoad()
       
        checkIfUserIsLoggedIn()
        //UserDefaults.standard.set(false, forKey: "isLoggedIn")
    }

    func checkIfUserIsLoggedIn() {
        if Auth.auth().currentUser?.uid == nil {
            perform(#selector(logOutAction), with:nil, afterDelay: 0)
        } else {
            let uid = Auth.auth().currentUser?.uid
            Database.database().reference().child("users").child(uid!).observeSingleEvent(of: .value, with: {(snapshot) in
                
                if let dictionary = snapshot.value as? [String: Any] {
                    self.nameLabel.text = dictionary["name"] as? String
                }
            }, withCancel: nil)
        }
    }
}
   /* @objc func handleLogOut() {
        do {
            try Auth.auth().signOut()
        }
        catch let logoutError {
            print(logoutError)
        }
        let loginController = LoginViewController()
        present(loginController, animated: true, completion: nil)
        }
    
 

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return 0
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of rows
        return 0
    }

    /*
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "reuseIdentifier", for: indexPath)

        // Configure the cell...

        return cell
    }
    */

    /*
    // Override to support conditional editing of the table view.
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the specified item to be editable.
        return true
    }
    */

    /*
    // Override to support editing the table view.
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            // Delete the row from the data source
            tableView.deleteRows(at: [indexPath], with: .fade)
        } else if editingStyle == .insert {
            // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
        }    
    }
    */

    /*
    // Override to support rearranging the table view.
    override func tableView(_ tableView: UITableView, moveRowAt fromIndexPath: IndexPath, to: IndexPath) {

    }
    */

    /*
    // Override to support conditional rearranging of the table view.
    override func tableView(_ tableView: UITableView, canMoveRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the item to be re-orderable.
        return true
    }
    */

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}*/
