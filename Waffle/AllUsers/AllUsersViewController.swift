//
//  AllUsersViewController.swift
//  Waffle
//
//  Created by Astghik Hakopian on 4/22/18.
//

import UIKit
import Firebase

class AllUsersViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {
    
    // MARK: - Properties
    
    @IBOutlet weak var spinner: UIActivityIndicatorView!
    @IBOutlet weak var tableView: UITableView!
    private let refreshControl = UIRefreshControl()
    var users: [User] = []
    let dispatchQueue = DispatchQueue(label: "Dispatch Queue", attributes: [], target: nil)
    
    // MARK: - Lifecycle methods
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.setupRefreshControl()
        
        tableView.register(UINib(nibName: "UsersTableViewCell", bundle: nil), forCellReuseIdentifier: "UsersTableViewCell")
        if (users.count == 0) {
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
    }
    override func viewWillAppear(_ animated: Bool) {
       super.viewWillAppear(animated)
        animateTable()
         loadItems()
    }
    
    
    // MARK: - UITableViewDataSource
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return users.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "UsersTableViewCell") as! UsersTableViewCell
        
        cell.nameLabel.text = users[indexPath.row].name
        cell.emailLabel.text = users[indexPath.row].email
        
        let imageUrl = URL(string: users[indexPath.row].photoURL)
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
        tap.userId = users[indexPath.row].id
        cell.addGestureRecognizer(tap)
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 80.0
    }
    
    
    // MARK: - Private Methods
    
   @objc private func fetchUsers() {
        Database.database().reference().child("users").observe(.childAdded, with: {(snapshot) in
            if let dictionary = snapshot.value as? [String: Any] {
                let user = User(json: dictionary)
                self.users.append(user)
                DispatchQueue.main.async {
                    self.tableView.reloadData()
                }
            }
        }, withCancel: nil)
    }
    
    @objc private func handleTap(gestureRecognizer: TapRecognizer) {
         performSegue(withIdentifier: "chatVCSegue", sender: gestureRecognizer)
    }
    
    @objc private func loadItems() {
        users.removeAll()
        
        fetchUsers()
        
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
        refreshControl.attributedTitle = NSAttributedString(string:"", attributes: [:])
    }
}

class TapRecognizer : UITapGestureRecognizer{
    var userId: String!
}
