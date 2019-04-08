import UIKit

class GameOverViewController: UIViewController {
    var winningTeam: Team?
    
    @IBOutlet weak var winningTeamText: UILabel!
    override func viewDidLoad() {
        print("Calling VIEW DIDID LOAD")
        super.viewDidLoad()
        self.navigationItem.hidesBackButton = true
        self.winningTeamText.text = self.winningTeam?.name
        if winningTeam?.name == "red" {
            self.winningTeamText.textColor = UIColor.red
        } else if winningTeam?.name == "blue" {
            self.winningTeamText.textColor = UIColor.blue
        }
    }
}
