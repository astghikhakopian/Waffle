//
//  RestAPIConstants.swift
//  Waffle
//
//  Created by Astghik Hakopian on 4/12/18.
//

import Foundation
import Firebase

struct Constants {
    struct refs {
        static let databaseRoot = Database.database().reference()
        static let databaseChats = databaseRoot.child("chats")
    }
}
