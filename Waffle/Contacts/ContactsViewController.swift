//
//  ContactsViewController.swift
//  Waffle
//
//  Created by Astghik Hakopian on 4/28/18.
//

import UIKit
import Firebase

class ContactsViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    
    // MARK: - Properties
    
    @IBOutlet weak var spinner: UIActivityIndicatorView!
    @IBOutlet weak var tableView: UITableView!
    
    private var contacts: [User] = []
    private var messagesReceiverIds = Set<String>()
    private var currentUserId: String!
    
    private let refreshControl = UIRefreshControl()
    
    
    // MARK: - Lifecycle Methods
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        spinner.startAnimating()
        tableView.separatorStyle = .none
        
        setupRefreshControl()
        addNavViewBarImage()
        
        currentUserId = UserDefaults.standard.value(forKey: "currentUserId") as! String
        
        tableView.register(UINib(nibName: "UsersTableViewCell", bundle: nil), forCellReuseIdentifier: UsersTableViewCell.id)
        
        loadItems()
        animateTable()
    }
    
    
    // MARK: - UITableViewDataSource
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return contacts.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "UsersTableViewCell") as! UsersTableViewCell
        cell.nameLabel.text = contacts[indexPath.row].name
        cell.emailLabel.text = contacts[indexPath.row].email
        
        cell.imageVIew.image = nil
        
        DispatchQueue.global(qos: .userInteractive).async {
            let imageUrl = URL(string: self.contacts[indexPath.row].photoURL)
            if let imageUrl = imageUrl {
                if let imageData = try? Data(contentsOf: imageUrl as URL) {
                    DispatchQueue.main.async {
                        if cell.imageVIew.image == nil {
                            cell.imageVIew.image = UIImage(data: imageData)
                        }
                    }
                }
            } else {
                DispatchQueue.main.async {
                    cell.imageVIew.image = UIImage(named: "defaultProfile")
                }
            }
        }
        
        let tap = TapRecognizer(target: self, action: #selector(self.handleTap(gestureRecognizer:)))
        tap.userId = contacts[indexPath.row].id
        cell.addGestureRecognizer(tap)
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 80.0
    }
    
    
    // MARK: - Private Methods
    
    @objc private func loadItems() {
        contacts.removeAll()
        fetchContacts()
        fetchCurrentUserMessagesIds()
        refreshControl.endRefreshing()
    }
    
    private func fetchContacts() {
        Database.database().reference().child("users").observe(.childAdded, with: {(snapshot) in
            if let dictionary = snapshot.value as? [String: Any] {
                let user = User(json: dictionary)
                if self.messagesReceiverIds.contains(user.id) {
                    self.contacts.append(user)
                }
                self.tableView.isHidden = false
                self.spinner.stopAnimating()
                self.tableView.reloadData()
                self.animateTable()
            }
        }, withCancel: nil)
    }
    
    private func fetchCurrentUserMessagesIds() {
        Database.database().reference().child("users").child(self.currentUserId).child("messages").observe(.childAdded, with: {(snapshot) in
            if let dictionary = snapshot.value as? [String: Any] {
                let message = Message(json: dictionary)
                self.messagesReceiverIds.insert(message.receiverId)
            }
        }, withCancel: nil)
    }
    
    // UI
    private func setupRefreshControl() {
        tableView.refreshControl = refreshControl
        refreshControl.addTarget(self, action: #selector(loadItems), for: .valueChanged)
        refreshControl.tintColor = UIColor(red: 232/255, green: 79/255, blue: 82/255, alpha: 1.0)
        refreshControl.attributedTitle = NSAttributedString(string: "Fetching Data...", attributes: [:])
    }
    
    private func animateTable() {
        DispatchQueue.main.async {
            let cells = self.tableView.visibleCells
            let tableViewHeight = self.tableView.bounds.size.height
            for cell in cells {
                cell.transform = CGAffineTransform(translationX: 0, y: tableViewHeight)
            }
            var delayCounter = 0
            for cell in cells {
                UIView.animate(withDuration: 1.75, delay: Double(delayCounter) * 0.05,usingSpringWithDamping: 0.8, initialSpringVelocity: 0, options: .curveEaseInOut, animations: {
                    cell.transform = CGAffineTransform.identity
                }, completion: nil)
                delayCounter += 1
            }
        }
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
    
    @objc private func handleTap(gestureRecognizer: TapRecognizer) {
        performSegue(withIdentifier: "chatVCSegue", sender: gestureRecognizer)
    }
    
    
    // MARK: - NavigationController
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "chatVCSegue" {
            let chatVC = segue.destination as! ChatVIewController
            let recognizer = sender as! TapRecognizer
            chatVC.friendId = recognizer.userId
        }
    }
}
