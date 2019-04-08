import UIKit

class LoginViewController: CaptureTheFlagViewController {
    @IBOutlet weak var errorTextField: UITextView!
    @IBOutlet weak var usernameText: UITextField!
    @IBOutlet weak var passwordText: UITextField!
    override func viewDidLoad() {
        super.viewDidLoad()
        let RRManager = WebSocketRequestResponse()
        self.serverAccess = ServerAccess(requestResponse: RRManager)
    }
    
    @IBAction func login(_ sender: Any) {
        if usernameText.text != nil && passwordText.text != nil {
            self.serverAccess?.initaiteConnection(username: usernameText.text!, password: passwordText.text!, callback: {(error) in
                if error != nil {
                    self.errorTextField.text = error?.rawValue
                } else {
                    self.performSegue(withIdentifier: "showMenu", sender: nil)
                }
            })
        }
    }
    
}
