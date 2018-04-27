//
//  Message.swift
//  Waffle
//
//  Created by Astghik Hakopian on 4/28/18.
//

import Foundation

struct Message {
    let senderName: String
    let mediaType: String
    let text: String
    let senderId: String
    let receiverId: String
    
    init(json: [String: Any]) {
        senderName = json["senderName"] as? String ?? ""
        mediaType = json["MediaType"] as? String ?? ""
        text = json["text"] as? String ?? ""
        receiverId = json["receiver"] as? String ?? ""
        senderId = json["senderID"] as? String ?? ""
    }
}
