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
    
    @IBOutlet weak var numberLabel: UILabel!
    @IBOutlet weak var emailLabel: UILabel!
    @IBOutlet weak var viewConstraint: NSLayoutConstraint!
    @IBOutlet weak var sideView: UIView!
    @IBOutlet weak var blurView: UIVisualEffectView!
    @IBOutlet weak var spinner: UIActivityIndicatorView!
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var imageOfUser: UIImageView!
    @IBOutlet weak var usernameLabel: UILabel!
    
    let dispatchQueue = DispatchQueue(label: "Dispatch Queue", attributes: [], target: nil)
    private var contacts: [User] = []
    private var messagesReceiverIds = Set<String>()
    private var currentUserId: String!
    private let refreshControl = UIRefreshControl()
   
    
    @IBAction func panGestureAction(_ sender: UIPanGestureRecognizer) {
        if sender.state == .began || sender.state == .changed {
            let translation = sender.translation(in: self.view).x
            if translation > 0 {
                if viewConstraint.constant < 20 {
                    UIView.animate(withDuration: 0.2, animations: {
                        self.viewConstraint.constant += translation / 10
                        self.view.layoutIfNeeded()
                        })
                }
            } else {
                if viewConstraint.constant > -175 {
                    UIView.animate(withDuration: 0.2, animations: {
                        self.viewConstraint.constant += translation / 10
                        self.view.layoutIfNeeded()
                    })
                }
               
            }
        } else if sender.state == .ended {
            if viewConstraint.constant < -100 {
                UIView.animate(withDuration: 0.2, animations: {
                    self.viewConstraint.constant = -175
                    self.view.layoutIfNeeded()
                })
            } else {
                UIView.animate(withDuration: 0.2, animations: {
                    self.viewConstraint.constant = 0
                    self.view.layoutIfNeeded()
                })
            }
        }
        
    }
    
    // MARK: - Lifecycle methods
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupRefreshControl()
        addNavViewBarImage()
        currentUserId = UserDefaults.standard.value(forKey: "currentUserId") as! String
        tableView.register(UINib(nibName: "UsersTableViewCell", bundle: nil), forCellReuseIdentifier: UsersTableViewCell.id)
        if contacts.count == 0 {
            tableView.separatorStyle = .none
            self.spinner.startAnimating()
            DispatchQueue.global().asyncAfter(deadline: .now() + 1) {
                DispatchQueue.main.async {
                    self.tableView.isHidden = false
                    self.spinner.stopAnimating()
                    self.spinner.isHidden = true
                    self.animateTable()
                    self.blurView.layer.cornerRadius = 15
                    self.sideView.layer.shadowColor = UIColor.red.cgColor
                    self.sideView.layer.shadowOpacity = 0.8
                    self.sideView.layer.shadowOffset = CGSize(width:5, height:0)
                    self.viewConstraint.constant = -175
                    self.settingsReload()
                    self.sideView.isHidden = false
                }
            }
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        dispatchQueue.async {
            self.loadItems()
            //self.settingsReload()
            
        }
    }
    
    
    // MARK: - UITableView DataSource
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return contacts.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "UsersTableViewCell") as! UsersTableViewCell
        cell.nameLabel.text = contacts[indexPath.row].name
        cell.emailLabel.text = contacts[indexPath.row].email
        DispatchQueue.global(qos: .userInteractive).async {
            let imageUrl = URL(string: self.contacts[indexPath.row].photoURL)
            if let theProfileImageUrl = imageUrl {
                do {
                    let imageData = try Data(contentsOf: theProfileImageUrl as URL)
                    DispatchQueue.main.async {
                        cell.imageVIew.image = UIImage(data: imageData)
                        cell.imageVIew.layer.borderWidth = 1.0
                        cell.imageVIew.layer.borderColor = UIColor.white.cgColor
                        cell.imageVIew.layer.masksToBounds = false
                        cell.imageVIew.layer.cornerRadius = cell.imageVIew.frame.size.height/2
                        cell.imageVIew.clipsToBounds = true
                    }
                    
                } catch {
                    print("Unable to load data: \(error)")
                }
            } else {
                DispatchQueue.main.async {
                    cell.imageVIew.layer.borderWidth=1.0
                    cell.imageVIew.layer.masksToBounds = false
                    cell.imageVIew.layer.cornerRadius = cell.imageVIew.frame.size.height/2
                    cell.imageVIew.layer.borderColor = UIColor.white.cgColor
                    cell.imageVIew.clipsToBounds = true
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
    
    private func fetchContacts() {
        dispatchQueue.async {
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
    }
    
    private func fetchCurrentUserMessagesIds() {
        dispatchQueue.async {
            Database.database().reference().child("users").child(self.currentUserId).child("messages").observe(.childAdded, with: {(snapshot) in
                if let dictionary = snapshot.value as? [String: Any] {
                    let message = Message(json: dictionary)
                    self.messagesReceiverIds.insert(message.receiverId)
                }
            }, withCancel: nil)
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
        tableView.refreshControl = refreshControl
        tableView.addSubview(refreshControl)
        refreshControl.addTarget(self, action: #selector(loadItems), for: .valueChanged)
        refreshControl.tintColor = UIColor(red: 232/255, green: 79/255, blue: 82/255, alpha: 1.0)
        refreshControl.attributedTitle = NSAttributedString(string: "Fetching Data...", attributes: [:])
    }
    
    private func addNavViewBarImage() {
        let navController = self.navigationController
        let logo = UIImage(named: "logo.png")
        let imageView = UIImageView(image:logo)
        self.navigationItem.titleView = imageView
        let bannerWidth = navController?.navigationBar.frame.size.width
        let bannerHeight = navController?.navigationBar.frame.size.height
        //let bannerX = bannerWidth! / 2 - (logo?.size.width)! / 2
        // let bannerY = bannerHeight! / 2 - (logo?.size.height)! / 2
        
        imageView.frame = CGRect(x: 0, y: 0, width: bannerWidth!, height:bannerHeight!)
        imageView.contentMode = .scaleAspectFit
        self.navigationItem.titleView = imageView
    }
    
    
    @objc private func handleTap(gestureRecognizer: TapRecognizer) {
        performSegue(withIdentifier: "chatVCSegue", sender: gestureRecognizer)
    }
    
    private func settingsReload() {
        self.dispatchQueue.async {
            let id = Auth.auth().currentUser?.uid
            Database.database().reference().child("users").child(id!).observeSingleEvent(of: .value, with: {(snapshot) in
                if let dictionary = snapshot.value as? [String: Any] {
                    DispatchQueue.main.async {
                        self.usernameLabel.text = (dictionary["name"] as! String)
                        self.emailLabel.text = (dictionary["email"] as! String)
                        self.numberLabel.text = (dictionary["phone number"] as! String)
                    }
                    if (dictionary["photoUrl"] as! String) != "" {
                        let theProfileImageURL = URL(string:(dictionary["photoUrl"]as! String))
                        do {
                            let imageData = try Data(contentsOf: theProfileImageURL!)
                            DispatchQueue.main.async {
                                self.imageOfUser.image = UIImage(data: imageData)
                                self.imageOfUser.layer.borderWidth = 1.0
                                self.imageOfUser.layer.borderColor = UIColor.white.cgColor
                                self.imageOfUser.layer.masksToBounds = false
                                self.imageOfUser.layer.cornerRadius = self.imageOfUser.frame.size.height/2
                                self.imageOfUser.clipsToBounds = true
                            }
                        } catch {
                            print("Unable to load data: \(error)")
                        }
                    } else {
                        DispatchQueue.main.async {
                            self.imageOfUser.image = UIImage(named: "defaultProfile")
                            self.imageOfUser.layer.borderWidth = 1.0
                            self.imageOfUser.layer.borderColor = UIColor.white.cgColor
                            self.imageOfUser.layer.masksToBounds = false
                            self.imageOfUser.layer.cornerRadius = self.imageOfUser.frame.size.height/2
                            self.imageOfUser.clipsToBounds = true
                            
                        }
                    }
                }
            })
        }
    }

    @objc private func loadItems() {
        contacts.removeAll()
        fetchCurrentUserMessagesIds()
        fetchContacts()
        DispatchQueue.main.async {
            self.refreshControl.endRefreshing()
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
}

