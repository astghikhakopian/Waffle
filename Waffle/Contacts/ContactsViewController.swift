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
    
    let dispatchQueue = DispatchQueue(label: "Dispatch Queue", attributes: [], target: nil)
    private var contacts: [User] = []
    private var messagesReceiverIds = Set<String>()
    private var currentUserId: String!
    private let refreshControl = UIRefreshControl()
    
    
    // MARK: - Lifecycle methods
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        currentUserId = UserDefaults.standard.value(forKey: "currentUserId") as! String
        tableView.register(UINib(nibName: "UsersTableViewCell", bundle: nil), forCellReuseIdentifier: "UsersTableViewCell")
        if (contacts.count == 0) {
            tableView.separatorStyle = .none
            spinner.startAnimating()
            dispatchQueue.async {
                Thread.sleep(forTimeInterval: 3)
                OperationQueue.main.addOperation() {
                    //self.tableView.separatorStyle = .singleLine
                    self.tableView.isHidden = false
                    self.spinner.isHidden = true
                    self.spinner.stopAnimating()
                    self.animateTable()
                }
            }
        }
        
        setupRefreshControl()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        animateTable()
        loadItems()
    }
    
    
    // MARK: - UITableViewDataSource
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return contacts.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "UsersTableViewCell") as! UsersTableViewCell
        cell.nameLabel.text = contacts[indexPath.row].name
        cell.emailLabel.text = contacts[indexPath.row].email
        let imageUrl = URL(string: contacts[indexPath.row].photoURL)
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
        let tap = TapRecognizer(target: self, action: #selector(self.handleTap(gestureRecognizer:)))
        tap.userId = contacts[indexPath.row].id
        cell.addGestureRecognizer(tap)
        return cell
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 80.0
    }
    
    
    // MARK: - Private Methods
    
    private func fetchContacts() {
        Database.database().reference().child("users").observe(.childAdded, with: {(snapshot) in
            if let dictionary = snapshot.value as? [String: Any] {
                let user = User(json: dictionary)
                if self.messagesReceiverIds.contains(user.id) {
                    self.contacts.append(user)
                }
                DispatchQueue.main.async {
                    self.tableView.reloadData()
                }
            }
        }, withCancel: nil)
    }
    
    private func fetchCurrentUserMessagesIds() {
        Database.database().reference().child("users").child(currentUserId).child("messages").observe(.childAdded, with: {(snapshot) in
            if let dictionary = snapshot.value as? [String: Any] {
                let message = Message(json: dictionary)
                self.messagesReceiverIds.insert(message.receiverId)
            }
        }, withCancel: nil)
    }
    
    private func animateTable() {
        tableView.reloadData()
        let cells = tableView.visibleCells
        let tableViewHeight = tableView.bounds.size.height
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
    
    private func setupRefreshControl() {
        if #available(iOS 10.0, *) {
            tableView.refreshControl = refreshControl
        } else {
            tableView.addSubview(refreshControl)
        }
        refreshControl.addTarget(self, action: #selector(loadItems), for: .valueChanged)
        
        refreshControl.tintColor = UIColor(red: 0.25, green: 0.72, blue: 0.85, alpha: 1.0)
        refreshControl.attributedTitle = NSAttributedString(string: "Fetching Data...", attributes: [:])
    }
    
    @objc private func handleTap(gestureRecognizer: TapRecognizer) {
        performSegue(withIdentifier: "chatVCSegue", sender: gestureRecognizer)
    }
    
    @objc private func loadItems() {
        contacts.removeAll()
        fetchCurrentUserMessagesIds()
    
        fetchContacts()
        refreshControl.endRefreshing()
    }
    
    // MARK: - NavigationController
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "chatVCSegue" {
            let chatVC = segue.destination as! ChatVIewController
            let recogniser = sender as! TapRecognizer
            chatVC.friendId = recogniser.userId
        }
    }
}

