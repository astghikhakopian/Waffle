//
//  UsersTableViewCell.swift
//  Waffle
//
//  Created by Astghik Hakopian on 4/22/18.
//

import UIKit

class UsersTableViewCell: UITableViewCell {
    static let id = "UsersTableViewCell"
    
    @IBOutlet weak var imageVIew: UIImageView!
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var emailLabel: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        imageVIew.layer.borderWidth = 1.0
        imageVIew.layer.borderColor = UIColor.white.cgColor
        imageVIew.layer.masksToBounds = false
        imageVIew.layer.cornerRadius = imageVIew.frame.size.height/2
        imageVIew.clipsToBounds = true
    }
}
