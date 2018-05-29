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
    
    var users: [User] = []
    
    private let refreshControl = UIRefreshControl()
    
    //    let dispatchQueue = DispatchQueue(label: "Dispatch Queue", attributes: [], target: nil)
    
    
    // MARK: - Lifecycle methods
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        spinner.startAnimating()
        tableView.separatorStyle = .none
        
        setupRefreshControl()
        addNavViewBarImage()
        
        tableView.register(UINib(nibName: "UsersTableViewCell", bundle: nil), forCellReuseIdentifier: UsersTableViewCell.id)
        
        loadItems()
        self.tableView.isHidden = false
        //                    self.animateTable()
        
        
    }
    
    
    // MARK: - UITableViewDataSource
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return users.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "UsersTableViewCell") as! UsersTableViewCell
        
        cell.nameLabel.text = users[indexPath.row].name
        cell.emailLabel.text = users[indexPath.row].email
        
        cell.imageVIew.image = nil
        
        DispatchQueue.global(qos: .userInteractive).async {
            let imageUrl = URL(string: self.users[indexPath.row].photoURL)
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
        tap.userId = users[indexPath.row].id
        cell.addGestureRecognizer(tap)
        
        return cell
        
    }
    
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 80.0
    }
    
    // MARK: - Private Methods
    
    @objc private func fetchUsers() {
        DispatchQueue.global(qos: .userInteractive).async {
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
    }
    
    @objc private func handleTap(gestureRecognizer: TapRecognizer) {
        performSegue(withIdentifier: "chatVCSegue", sender: gestureRecognizer)
    }
    
    @objc private func loadItems() {
        DispatchQueue.global(qos: .userInteractive).async {
            self.users.removeAll()
            self.fetchUsers()
            DispatchQueue.main.async {
                self.refreshControl.endRefreshing()
            }
        }
    }
    
    
    // MARK: - NavigationController
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "chatVCSegue" {
            let chatVC = segue.destination as! ChatVIewController
            let recognizer = sender as! TapRecognizer
            chatVC.friendId = recognizer.userId
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
        tableView.refreshControl = refreshControl
        tableView.addSubview(refreshControl)
        refreshControl.addTarget(self, action: #selector(loadItems), for: .valueChanged)
        refreshControl.tintColor = UIColor(red: 232/255, green: 79/255, blue: 82/255, alpha: 1.0)
        refreshControl.attributedTitle = NSAttributedString(string:"", attributes: [:])
    }
    
    // MARK: - NavigationController
}

class TapRecognizer: UITapGestureRecognizer {
    var userId: String!
}
