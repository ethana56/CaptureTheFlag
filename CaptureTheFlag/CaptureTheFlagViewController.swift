import UIKit
import CoreLocation

class CaptureTheFlagViewController: UIViewController {
    var serverAccess: ServerAccess?
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let nextViewController = segue.destination as? CaptureTheFlagViewController {
            nextViewController.serverAccess = self.serverAccess
        }
    }

}
