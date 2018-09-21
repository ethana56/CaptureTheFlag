//
//  CreateAccountViewController.swift
//  
//
//  Created by Ethan Abrams on 9/17/18.
//

import UIKit

class CreateAccountViewController: CaptureTheFlagViewController {

    @IBOutlet weak var confirmPasswordINput: UITextField!
    @IBOutlet weak var passwordInput: UITextField!
    @IBOutlet weak var usernameInput: UITextField!
    override func viewDidLoad() {
        super.viewDidLoad()

    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        
    }
    
    @IBAction func createAccount(_ sender: Any) {
        print("create account button is being pressed")
        print("\(passwordInput.text!) \(usernameInput.text!)")
        if usernameInput.text != nil && passwordInput.text != nil {
            print("its getting this far")
            self.serverAccess?.createAccount(username: usernameInput.text!, password: passwordInput.text!, callback: {(error) in
                if error != nil {
                    print(error!)
                } else {
                    self.performSegue(withIdentifier: "fromCreateAccount", sender: nil)
                }
            })
        }
    }
    

}
