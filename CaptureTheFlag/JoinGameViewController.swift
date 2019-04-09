import UIKit
import SwiftWebSocket
import CoreLocation

class JoinGameViewController: CaptureTheFlagViewController{
    @IBOutlet weak var taggedView: UITextView!
    @IBOutlet weak var createGameButton: UIButton!
    @IBOutlet weak var success: UITextView!
    @IBOutlet weak var gameKeyText: UITextField!
    @IBOutlet weak var usernameText: UITextField!
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        
    
    }
    
    @IBAction func joinGame(_ sender: Any) {
       self.serverAccess!.joinGame(key: gameKeyText.text!, playerName: usernameText.text!, callback: {[unowned self] (error) in
        if error != nil {
            self.handleError(error: error!)
        } else {
            self.serverAccess!.getGameState(callback: {[unowned self](state, error) in
                print("STATE: \(state)")
                if error != nil {
                    
                } else {
                    switch state {
                    case 0:
                        self.performSegue(withIdentifier: "fromJoinToLobby", sender: nil)
                    default:
                        print()
                    }
                }
            })
        }
       })
    }
    
    private func handleError(error: GameError){
        switch error {
        case GameError.serverError:
            break
            //TODO: perform segue to error viewcontroller
        case GameError.gameDoesNotExist:
            self.success.text = "Invalid Game Key"
        default:
            break
        }
    }
    
    deinit {
        print("joinGameViewDeinit")
    }
}

