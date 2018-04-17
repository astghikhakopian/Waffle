//
//  ChatVIewController.swift
//  Waffle
//
//  Created by Ben on 4/17/18.
//

import UIKit
import JSQMessagesViewController

class ChatVIewController: JSQMessagesViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        self.senderId = "1"
        self.senderDisplayName = "Ben"
    }

}
