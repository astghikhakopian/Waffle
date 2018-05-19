//
//  LastTutorialViewController.swift
//  Waffle
//
//  Created by Sierra os on 5/18/18.
//

import UIKit

class LastTutorialViewController: UIViewController {

    @IBAction func nextButtonAction(_ sender: Any) {
        moveToVC(withIdentifier: "loggedInVC")
    }
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    private func moveToVC(withIdentifier identifier: String) {
        if let viewController = self.storyboard?.instantiateViewController(withIdentifier: identifier) {
            UIApplication.shared.keyWindow?.rootViewController = viewController
            self.dismiss(animated: true, completion: nil)
        }
    }

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
