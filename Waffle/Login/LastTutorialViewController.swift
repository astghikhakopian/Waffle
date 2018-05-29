//
//  LastTutorialViewController.swift
//  Waffle
//
//  Created by Sierra os on 5/18/18.
//

import UIKit

class LastTutorialViewController: UIViewController {

    // MARK: - Actions
    
    @IBAction func nextButtonAction(_ sender: Any) {
        if let viewController = self.storyboard?.instantiateViewController(withIdentifier: "loggedInVC") {
            UIApplication.shared.keyWindow?.rootViewController = viewController
            self.dismiss(animated: true, completion: nil)
        }
    }
}
