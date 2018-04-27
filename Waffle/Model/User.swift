//
//  User.swift
//  Waffle
//
//  Created by Astghik Hakopian on 4/22/18.
//

import Foundation

struct User: Hashable {
    var name: String
    var email: String
    var photoURL: String
    var id: String
    
    init (json: [String: Any]) {
        name = json["name"] as? String ?? ""
        email = json["email"] as? String ?? ""
        id = json["id"] as? String ?? ""
        photoURL = json["photoUrl"] as? String ?? ""
    }
}
