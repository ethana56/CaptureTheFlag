import UIKit

class GameLobbyCell: UITableViewCell {
    
    
    @IBOutlet weak var teamNameLabel: UILabel!
    @IBOutlet weak var playerNameLabel: UILabel!
    weak var player: Player?
    weak var team: Team?
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
    func setPlayer(player: Player) {
        self.player = player
        self.playerNameLabel.text = player.name
    }
    
    func setTeam(team: Team) {
        self.team = team
        self.teamNameLabel.text = team.name
    }
    
    func setPlayerName(name: String) {
        self.playerNameLabel.text = name
    }
    
    func setTeam(teamName: String) {
        self.teamNameLabel.text = teamName
    }
}
