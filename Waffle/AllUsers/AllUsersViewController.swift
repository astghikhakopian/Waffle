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
    
    @IBOutlet weak var numberLabel: UILabel!
    @IBOutlet weak var emailLabel: UILabel!
    @IBOutlet weak var viewConstraint: NSLayoutConstraint!
    @IBOutlet weak var sideView: UIView!
    @IBOutlet weak var blurView: UIVisualEffectView!
    @IBOutlet weak var spinner: UIActivityIndicatorView!
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var imageOfUser: UIImageView!
    @IBOutlet weak var usernameLabel: UILabel!
    private let refreshControl = UIRefreshControl()
    var users: [User] = []
    let dispatchQueue = DispatchQueue(label: "Dispatch Queue", attributes: [], target: nil)
    
    //MARK: - Actions
    
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
        tableView.register(UINib(nibName: "UsersTableViewCell", bundle: nil), forCellReuseIdentifier: UsersTableViewCell.id)
        if users.count == 0 {
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
        self.loadItems()
        
    }
    
    
    // MARK: - UITableViewDataSource
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return users.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "UsersTableViewCell") as! UsersTableViewCell
        cell.nameLabel.text = users[indexPath.row].name
        cell.emailLabel.text = users[indexPath.row].email
        DispatchQueue.global(qos: .userInteractive).async {
            let imageUrl = URL(string: self.users[indexPath.row].photoURL)
            if let theProfileImageUrl = imageUrl {
                do {
                    let imageData = try Data(contentsOf: theProfileImageUrl as URL)
                    DispatchQueue.main.async {
                        cell.imageVIew.image = UIImage(data: imageData)
                        cell.imageVIew.layer.borderWidth=1.0
                        cell.imageVIew.layer.borderColor = UIColor.white.cgColor
                        cell.imageVIew.layer.masksToBounds = false
                        cell.imageVIew.layer.cornerRadius = cell.imageVIew.frame.size.height / 2
                        cell.imageVIew.clipsToBounds = true
                    }
                } catch {
                    print("Unable to load data: \(error)")
                }
            } else {
                DispatchQueue.main.async {
                    cell.imageVIew.layer.borderWidth=1.0
                    cell.imageVIew.layer.masksToBounds = false
                    cell.imageVIew.layer.cornerRadius = cell.imageVIew.frame.size.height / 2
                    cell.imageVIew.layer.borderColor = UIColor.white.cgColor
                    cell.imageVIew.clipsToBounds = true
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
                        }catch {
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
        //let bannerX = bannerWidth! / 2 - (logo?.size.width)! / 2
        // let bannerY = bannerHeight! / 2 - (logo?.size.height)! / 2
        
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
