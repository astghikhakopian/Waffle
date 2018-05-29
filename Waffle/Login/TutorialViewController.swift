//
//  TutorialViewController.swift
//  Waffle
//
//  Created by Sierra os on 5/18/18.
//

import UIKit

class TutorialViewController: UIViewController {

    // MARK: - Properties
    
    @IBOutlet var tutorialView: UIView!
    
    
    // MARK: - Actions
    
    @IBAction func tryButtonAction(_ sender: Any) {
        let viewController = self.storyboard?.instantiateViewController(withIdentifier: "tutorialVC2")
        UIApplication.shared.keyWindow?.rootViewController = viewController
    }
    
    @IBAction func skipButtonAction(_ sender: Any) {
        if let viewController = self.storyboard?.instantiateViewController(withIdentifier: "loggedInVC") {
            UIApplication.shared.keyWindow?.rootViewController = viewController
            self.dismiss(animated: true, completion: nil)
        }
    }
}
