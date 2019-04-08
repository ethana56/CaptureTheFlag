
import UIKit

class GameLobbyViewController: CaptureTheFlagViewController, UITableViewDelegate, UITableViewDataSource {
    @IBOutlet weak var GameNameText: UITextView!
    @IBOutlet weak var tableView: UITableView!
    var players = Set<Player>()
    var teams = [Team]()
    var listenerKeys = [GameListenerKey]()
    var userPlayer: Player?
    var teamSelect = false
    var teamSelected: Team?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.tableView.delegate = self
        self.tableView.dataSource = self
        self.serverAccess!.getPlayerTeamsFlags(callback: {(players, flags, teams, error) in
            if error != nil {
                self.handleError(error!)
                return
            }
            self.teams = teams!
            self.players = Set<Player>(players!)
            self.serverAccess!.getUserPlayer(callback: {(player, error) in
                if error != nil {
                    self.handleError(error!)
                    return
                }
                self.userPlayer = player!
                self.tableView.reloadData()
                self.createListeners()
            })
        })
    }


    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return players.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "playerCell", for: indexPath) as? GameLobbyCell  else {
            fatalError("")
        }
        let players = Array<Player>(self.players)
        let player = players[indexPath.row]
        cell.setPlayer(player: player)
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if self.teamSelect {
            guard let cell = tableView.dequeueReusableCell(withIdentifier: "playerCell", for: indexPath) as? GameLobbyCell else {
                fatalError("")
            }
            if self.userPlayer?.isLeader() != nil && self.userPlayer!.isLeader() {
                self.serverAccess?.makeLeader(player: cell.player!, callback: {(error) in
                    if error != nil {
                        self.handleError(error!)
                        return
                    }
                    self.tableView.reloadData()
                })
            }
        }
        self.tableView.deselectRow(at: indexPath, animated: true)
    }

    @IBAction func startGame(_ sender: Any) {
        self.serverAccess?.nextGameState(callback: {(error) in
            if error != nil {
                self.handleError(error!)
                return
            }
        })
    }
    
    private func createListeners() {
        self.listenerKeys.append(
            self.serverAccess!.addPlayerAddedListener(callback: {(player) in
                self.players.insert(player)
                self.tableView.reloadData()
        }))
        
        self.listenerKeys.append(
            self.serverAccess!.addPlayerRemovedListener(callback: {(player) in
                self.players.remove(player)
                self.tableView.reloadData()
        }))
        
        self.listenerKeys.append(
            self.serverAccess!.addGameStateChangedListener(callback: {(gameState) in
                print("lobby the game state changed")
                if gameState == 1 {
                    self.removeListeners()
                    self.performSegue(withIdentifier: "toMapView", sender: nil)
                } else {
                    //TODO: go to something went wrong view controller
                }
            }))
    }
    
    private func removeListeners() {
        for listener in self.listenerKeys {
            self.serverAccess?.removeListener(listener)
        }
    }
    
    private func handleError(_ error: GameError) {
        
    }
}




