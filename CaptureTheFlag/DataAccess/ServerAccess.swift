import Foundation

struct GameListenerKey {
    let key: UUID
    init(key: UUID) {
        self.key = key
    }
}

typealias GameState = ([Player], [Flag], [Team], GameBoundary?, String, Int, String)
typealias JSON = [String : Any]
final class ServerAccess {
    private let point: AsyncRequestResponse
    private var listenerKeys = Dictionary<UUID, ListenerKey>()
    private var userKey: String?
    private var registeredPlayers = [String : Player]()
    private var registeredFlags = [String : Flag]()
    private var registeredTeams = [Int : Team]()
    var onReconnect: (() -> ())?

    init(requestResponse: AsyncRequestResponse) {
        self.point = requestResponse
        self.point.onReconnect = {
            print("On reconnect being called")
            self.onReconnect?()
        }
        self.enablePlayerJoinedTeamListener()
        self.enableTagListener()
        self.enableLocationListener()
        self.enablePlayerMadeLeaderListener()
        self.enablePlayerPickedUpFlagListener()
        self.enablePlayerDroppedFlagListener()
    }
    
    //capture-the-flag-server.herokuapp.com/
    //192.168.86.115:8000
    
    func initaiteConnection(username: String, password: String, callback: @escaping (GameError?) -> ()) {
        var request = URLRequest(url: URL(string: "http://localhost:8000/authenticate")!)
        request.httpMethod = "POST"
        request.setValue("Application/json", forHTTPHeaderField: "Content-Type")
        let paramDictionary = ["username" : username, "password" : password]
        guard let httpBody = try? JSONSerialization.data(withJSONObject: paramDictionary, options: []) else {
            return
        }
        request.httpBody = httpBody
        let session = URLSession.shared
        session.dataTask(with: request) { (data, urlResponse, error) in
            if let response = urlResponse {
                print(response)
            }
            if let data = data {
                do {
                    let json = try JSONSerialization.jsonObject(with: data, options: []) as! [String : String]
                    self.userKey = json["key"]
                    self.point.close(closed: {() in
                        self.point.open(address: "ws://localhost:8000/", additionalHTTPHeaders: ["authKey" : self.userKey!])
                        DispatchQueue.main.async {
                            callback(nil)
                        }
                    })
                } catch {
                    print(error)
                }
            }
        }.resume()
    }
    
    
    //172.116.137.45
    func createAccount(username: String, password: String, callback: @escaping (GameError?) -> ()) {
        var request = URLRequest(url: URL(string: "http:localhost:8000/createAccount")!)
        request.httpMethod = "POST"
        request.setValue("Application/json", forHTTPHeaderField: "Content-Type")
        let paramDictionary = ["username" : username, "password" : password]
        guard let httpBody = try? JSONSerialization.data(withJSONObject: paramDictionary, options: []) else {
            return
        }
        request.httpBody = httpBody
        let session = URLSession.shared
        session.dataTask(with: request) {(data, urlResponse, error) in
            if let data = data {
                DispatchQueue.main.async {
                    callback(nil)
                }
            } else {
                /*TODO: handle this error*/
                print("Fail")
            }
        }.resume()
    }
    
    func addTeamAddedListener(callback: @escaping (Team) -> ()) -> GameListenerKey {
        //print("TEAM ADDED IS BEING CALLED")
        let listenerKey = self.point.addListener(for: "teamAdded", callback: {(data) in
            let dataAsDict = data as! [String:Any]
                do {
                    let team = self.constructTeam(teamJson: dataAsDict, players: [Player](), flags: [Flag]())
                    callback(team)
                } catch {
                    /*Handle this error*/
                    print(error)
                }
            
        })
        return GameListenerKey(key: listenerKey.key)
    }
    
    private func register(players: [Player]) {
        for player in players {
            self.registeredPlayers[player.id] = player
        }
    }
    
    private func register(flags: [Flag]) {
        for flag in flags {
            self.registeredFlags[flag.id] = flag
        }
    }
    
    private func register(teams: [Team]) {
        for team in teams {
            self.registeredTeams[team.id] = team
        }
    }
    
    private func register(player: Player) {
        self.registeredPlayers[player.id] = player
    }
    
    private func register(flag: Flag) {
        self.registeredFlags[flag.id] = flag
    }
    
    private func enablePlayerPickedUpFlagListener() {
        self.point.addListener(for: "flagPickedUp", callback: {(data) in
            let rawData = data as! JSON
            let playerId = rawData["playerId"] as! String
            let flagId = rawData["flagId"] as! String
            let player = self.registeredPlayers[playerId]
            let flag = self.registeredFlags[flagId]
            if player != nil && flag != nil {
                player!.set(flag: flag!)
                flag!.setHeld(by: player!)
            }
        })
    }
    
    private func enablePlayerDroppedFlagListener() {
        self.point.addListener(for: "flagDropped", callback: {(data) in
            let rawData = data as! JSON
            let playerId = rawData["playerId"] as! String
            let flagId = rawData["flagId"] as! String
            let rawLocation = rawData["location"] as! [String : String]
            let location = Location(dict: rawLocation)!
            let flag = self.registeredFlags[flagId]
            let player = self.registeredPlayers[playerId]
            if flag != nil && player != nil {
                flag!.set(location: location)
                flag!.setDropped()
                player!.dropFlag()
            }
        })
    }
    
    private func enablePlayerJoinedTeamListener() {
        self.point.addListener(for: "playerJoinedTeam", callback: {(data) in
            let rawData = data as! JSON
            let playerId = rawData["id"] as! String
            let teamId = rawData["team"] as! Int
            let player = self.registeredPlayers[playerId]
            let team = self.registeredTeams[teamId]
            if player != nil && team != nil {
                team!.add(player: player!)
            }
        })
    }
    
    private func enableLocationListener() {
        self.point.addListener(for: "locationChanged", callback: {(data) in
            let rawData = data as! JSON
            let id = rawData["playerId"] as! String
            let newLocation = Location(dict: rawData["newLocation"] as? [String : String])
            let player = self.registeredPlayers[id]
            if player != nil && newLocation != nil {
                player!.set(location: newLocation!)
            }
        })
    }
    
    private func enableTagListener() {
        self.point.addListener(for: "playerTagged", callback: {(data) in
            let rawData = data as! JSON
            let playerId = rawData["playerId"] as! String
            let taggingPlayerId = rawData["taggingPlayerId"] as! String
            let player = self.registeredPlayers[playerId]
            let taggingPlayer = self.registeredPlayers[taggingPlayerId]
            if player != nil {
                player!.set(tagged: true, tagger: taggingPlayer)
            }
        })
        self.point.addListener(for: "untagged", callback: {(data) in
            let rawData = data as! JSON
            let playerId = rawData["playerId"] as! String
            if let player = self.registeredPlayers[playerId] {
                player.set(tagged: false, tagger: nil)
            }
        })
    }
    
    private func enablePlayerMadeLeaderListener() {
        self.point.addListener(for: "playerMadeLeader", callback: {(data) in
            let rawData = data as! JSON
            let playerId = rawData["playerId"] as! String
            let player = self.registeredPlayers[playerId]
            if player != nil {
                player!.setLeader(true)
            }
        })
    }
    
    func getCurrentGameState(callback: @escaping (GameState?, GameError?) -> ()) {
        self.point.sendMessage(command: "getCurrentGameState", payLoad: nil, callback: {(data, error) in
            if error != nil {
                callback(nil, GameError.serverError)
                return
            }
            let protorawData = data as! JSON
            if let appError = protorawData["error"] as? String {
                callback(nil, GameError(rawValue: appError))
                return
            }
            let rawData = protorawData["stateData"] as! JSON
            let rawPlayers = rawData["players"] as! [JSON]
            let rawFlags = rawData["flags"] as! [JSON]
            let rawTeams = rawData["teams"] as! [JSON]
            let rawGameBoundary = rawData["boundary"] as? JSON
            let name = rawData["name"] as! String
            let gameState = rawData["gameState"] as! Int
            let currentPlayerId = rawData["userPlayerId"] as! String
            var players = [Player]()
            var flags = [Flag]()
            var teams = [Team]()
            for rawPlayer in rawPlayers {
                players.append(self.constructPlayer(playerJson: rawPlayer))
            }
            for rawFlag in rawFlags {
                flags.append(self.constructFlag(flagJson: rawFlag))
            }
            for rawTeam in rawTeams {
                teams.append(self.constructTeam(teamJson: rawTeam, players: players, flags: flags))
            }
            let gameBoundary = GameBoundary(json: rawGameBoundary)
            self.register(players: players)
            self.register(flags: flags)
            self.register(teams: teams)
            callback((players, flags, teams, gameBoundary, name, gameState, currentPlayerId), nil)
        })
    }
    
    func getUserPlayer(callback: @escaping (Player?, GameError?) -> ()) {
        self.point.sendMessage(command: "getPlayerInfo", payLoad: nil, callback: {(data, error) in
            if error != nil {
                callback(nil, GameError.serverError)
                return
            }
            let rawData = data as! JSON
            if let appError = rawData["error"] {
                callback(nil, GameError(rawValue: appError as! String))
                return
            }
            let playerData = rawData["player"] as! JSON
            let playerId = playerData["id"] as! String
            var player = self.registeredPlayers[playerId]
            if player != nil {
                callback(player, nil)
                return
            }
        })
    }
    
    func addGameOverListener(callback: @escaping (Team?) -> ()) -> GameListenerKey {
        let listenerKey = self.point.addListener(for: "gameOver", callback: {(data) in
            let dataAsDict = data as! JSON
            let teamJSON = dataAsDict["winningTeam"] as! JSON
            if let winningTeam = dataAsDict["winningTeam"] as? [String: Any] {
                do {
                    let team = self.constructTeam(teamJson: winningTeam, players: [Player](), flags: [Flag]())
                    callback(team)
                } catch {
                    print(error)
                }
            }
            callback(nil)
        })
        return GameListenerKey(key: listenerKey.key)
    }
    
    func addBoundaryAddedListener(callback: @escaping (GameBoundary) -> ()) -> GameListenerKey {
        let listenerKey = self.point.addListener(for: "boundaryCreated", callback: {(data) in
            let dataAsDict = data as! [String : Any]
            let boundaryDict = dataAsDict["boundary"] as! [String:Any]
            let centerDict = boundaryDict["center"]! as! [String: Double]
            let location = Location(latitude: centerDict["latitude"]!, longitude: centerDict["longitude"]!)
            let teamSides = boundaryDict["teamSides"] as! [String:String]
            let gameBoundary = GameBoundary(location: location, direction: BoundaryDirection(rawValue: boundaryDict["direction"] as! String)!, teamSides: teamSides)
            callback(gameBoundary)
        })
        return GameListenerKey(key: listenerKey.key)
    }
    
    
    
    func removeListener(_ gameListerKey: GameListenerKey) {
        if self.listenerKeys[gameListerKey.key] != nil {
            self.point.removeListener(listenerKey: self.listenerKeys[gameListerKey.key]!)
            self.listenerKeys.removeValue(forKey: gameListerKey.key)
        }
    }
    
    func addPlayerAddedListener(callback: @escaping (Player) -> ()) -> GameListenerKey {
        let listenerKey = self.point.addListener(for: "playerAdded", callback: {(data) in
            let rawData = data as! JSON
            let player = self.constructPlayer(playerJson: rawData)
            self.register(player: player)
            callback(player)
        })
        return GameListenerKey(key: listenerKey.key)
    }
    
    func addPlayerRemovedListener(callback: @escaping (Player) -> ()) -> GameListenerKey {
        let listenerKey = self.point.addListener(for: "playerRemoved", callback: {(data) in
            let playerId = data as! String
            let player = self.registeredPlayers[playerId]
            if player != nil {
                self.registeredPlayers.removeValue(forKey: playerId)
                callback(player!)
            }
        })
        self.listenerKeys[listenerKey.key] = listenerKey
        return GameListenerKey(key: listenerKey.key)
    }
    
    func addGameStateChangedListener(callback: @escaping (Int) -> ()) -> GameListenerKey {
        let listenerKey = self.point.addListener(for: "gameStateChanged", callback: {(data) in
            let dataAsDict = data as! [String:Int]
            callback(dataAsDict["gameState"]!)
        })
        self.listenerKeys[listenerKey.key] = listenerKey
        return GameListenerKey(key: listenerKey.key)
    }
    
    func addFlagAddedListener(callback: @escaping (Flag) -> ()) -> GameListenerKey {
        let listenerKey = self.point.addListener(for: "flagAdded", callback: {(data) in
            let dataAsDict = data as! [String : Any]
            let teamIdOfFlag = dataAsDict["teamId"] as! Int
            let flagAsDict = dataAsDict["flag"] as! JSON
            let flag = self.constructFlag(flagJson: flagAsDict)
            self.registeredFlags[flag.id] = flag
            if let teamOfFlag = self.registeredTeams[teamIdOfFlag] {
                teamOfFlag.add(flag: flag)
            }
            callback(flag)
        })
        return GameListenerKey(key: listenerKey.key)
    }
    
    func updateLocation(latitude: String, longitude: String) {
        let dataToSend = [
            "latitude" : latitude,
            "longitude" : longitude
        ]
        self.point.sendMessage(command: "updateLocation", payLoad: dataToSend, callback: nil)
    }
    
    func addPlayerToTeam(player: Player, team: Team, callback: @escaping (GameError?) -> ()) {
        let payload = [
            "playerId":player.id,
            "teamId":String(team.id)
        ]
        self.point.sendMessage(command: "addPlayerToTeam", payLoad: payload, callback: {(data, error) in
            if error != nil {
                print(error!.description)
                callback(GameError.serverError)
                return
            }
            let dataAsDict = data as! [String:Any]
            if !dataAsDict.isEmpty {
                let appError = dataAsDict["error"] as! String
                callback(GameError(rawValue: appError))
            } else {
                callback(nil)
            }
        })
    }
    
    
    
    func createGame(key: String, gameName: String, callback: @escaping (GameError?) -> ()) {
        let dataToSend = [
            "key" : key,
            "gameName" : gameName
        ]
        self.point.sendMessage(command: "createGame", payLoad: dataToSend, callback: {(data, error) in
            if error != nil {
                print(error!.description)
                callback(GameError.serverError)
                return
            }
            let dataAsDict = data as! [String: Any]
            if !dataAsDict.isEmpty {
                let appError = dataAsDict["error"] as! String
                callback(GameError(rawValue: appError))
            } else {
                callback(nil)
            }
        })
    }
    
    func joinGame(key: String, playerName: String, callback: @escaping (GameError?) -> ()) {
        let dataToSend = [
            "key" : key,
            "playerName" : playerName
        ]
        self.point.sendMessage(command: "joinGame", payLoad: dataToSend, callback: {(data, error) in
            if error != nil {
                print(error!.description)
                callback(GameError.serverError)
                return
            }
            let dataAsDict = data as! [String:Any]
            if !dataAsDict.isEmpty {
                let appError = dataAsDict["error"] as! String
                callback(GameError(rawValue: appError))
            } else {
                callback(nil)
            }
        })
    }
    
    func createFlag(latitude: String, longitude: String, callback: @escaping (GameError?) -> ()) {
        let dataToSend = [
            "latitude" : latitude,
            "longitude" : longitude
        ]
        self.point.sendMessage(command: "createFlag", payLoad: dataToSend, callback: {(data, error) in
            if error != nil {
                print(error!.description)
                callback(GameError.serverError)
                return
            }
            let dataAsDict = data as! [String:String]
            if let appError = dataAsDict["error"] {
                callback(GameError(rawValue: appError)!)
            } else {
                callback(nil)
            }
        })
    }
    
    func tagPlayer(player: Player,  callback: @escaping (GameError?) -> ()) {
        let dataToSend = [
            "playerToTagId" : player.id
        ]
        self.point.sendMessage(command: "tagPlayer", payLoad: dataToSend, callback: {(data, error) in
            if error != nil {
                print(error!.description)
                callback(GameError.serverError)
                return
            }
            let dataAsDict = data as! [String:String]
            if let appError = dataAsDict["error"] {
                callback(GameError(rawValue: appError))
                print("Error in tagplayer \(GameError(rawValue: appError))")
            } else {
                callback(nil)
            }
        })
        
    }
    
    func getGameState(callback: @escaping (Int?, GameError?) -> ()) {
        self.point.sendMessage(command: "getGameState", payLoad: nil, callback: {(data, error) in
            if error != nil  {
                print(error!.description)
                callback(nil, GameError.serverError)
                return
            }
            let dataAsDict = data as! [String:Any]
            if let errorFromData = dataAsDict["error"] {
                let appError = errorFromData as! String
                callback(nil, GameError(rawValue: appError))
            } else {
                let gameState = dataAsDict["gameState"] as! Int
                callback(gameState, nil)
            }
        })
        
    }
    
    func dropFlag(callback: @escaping (GameError?) -> ()) {
        self.point.sendMessage(command: "dropFlag", payLoad: nil, callback: {(data, error) in
            if let error = error {
                callback(GameError.serverError)
            } else {
                callback(nil)
            }
        })
    }
    
    func makeLeader(player: Player, callback: @escaping (GameError?) -> ()) {
        self.point.sendMessage(command: "makeLeader", payLoad: ["playerId":player.id], callback: {(data, error) in
            if error != nil {
                callback(GameError.serverError)
                return
            }
            let errorDict = data as! [String:String]
            if let error = errorDict["error"] as String? {
                callback(GameError(rawValue: error))
                return
            }
            callback(nil)
        })
    }
    
    func getPlayerTeamsFlags(callback: @escaping ([Player]?, [Flag]?, [Team]?, GameError?) -> ()) {
        var players = [Player]()
        var flags = [Flag]()
        var teams = [Team]()
        self.point.sendMessage(command: "getPlayersFlagsTeams", payLoad: nil, callback: {(data, error) in
            if error != nil {
                callback(nil, nil, nil, GameError.serverError)
                return
            }
            let rawData = (data as! JSON)["playersFlagsTeams"] as! JSON
            if let appError = rawData["error"] as? String {
                callback(nil, nil, nil, GameError(rawValue: appError ))
                return
            }
            let rawPlayers = rawData["players"] as! [JSON]
            let rawFlags = rawData["flags"] as! [JSON]
            let rawTeams = rawData["teams"] as! [JSON]
            for rawPlayer in rawPlayers {
                players.append(self.constructPlayer(playerJson: rawPlayer))
            }
            for rawFlag in rawFlags {
                flags.append(self.constructFlag(flagJson: rawFlag))
            }
            for rawTeam in rawTeams {
                teams.append(self.constructTeam(teamJson: rawTeam, players: players, flags: flags))
            }
            self.register(players: players)
            self.register(flags: flags)
            self.register(teams: teams)
            callback(players, flags, teams, nil)
        })
    }
    
    func pickUpFlag(flag: Flag, callback: @escaping (GameError?) -> ()) {
        let payLoad = [
            "flagId" : flag.id
        ]
        self.point.sendMessage(command: "pickUpFlag", payLoad: payLoad, callback: {(data, error) in
            if error != nil {
                print(error!.description)
                callback(GameError.serverError)
                return
            }
            let dataAsDict = data as! [String: String]
            if let appError = dataAsDict["error"] {
                callback(GameError(rawValue: appError))
            } else {
                callback(nil)
            }
        })
    }
    
    func createGameBoundary(location: Location, direction: BoundaryDirection, callback: @escaping (GameError?) -> ()) {
        let payLoad = [
            "latitude" : location.latitude,
            "longitude" : location.longitude,
            "direction" : direction.rawValue
        ] as [String: Any]
        
        self.point.sendMessage(command: "setBoundary", payLoad: payLoad, callback: {(data, error) in
            if error != nil {
                callback(GameError.serverError)
                return
            }
            let dataAsDict = data as! [String:String]
            if let appError = dataAsDict["error"] {
                let errorString = appError as! String
                callback(GameError(rawValue: errorString))
            } else {
                callback(nil)
            }
        })
    }
    
    func createTeam(teamName: String, callback: @escaping (GameError?) -> ()) {
        let payLoad = [
            "teamName" : teamName
        ]
        self.point.sendMessage(command: "createTeam", payLoad: payLoad, callback: {(data, error) in
            if error != nil {
                print(error!.description)
                callback(GameError.serverError)
                return
            }
            let dataAsDict = data as! [String:Any]
            if let appError = dataAsDict["error"] {
                let errorString = appError as! String
                callback(GameError(rawValue: errorString))
            } else {
                callback(nil)
            }
        })
    }
    
    func joinTeam(team: Team, callback: @escaping (GameError?) -> ()) {
        let payload = [
            "teamId" : String(team.id)
        ]
        self.point.sendMessage(command: "joinTeam", payLoad: payload, callback: {(data, error) in
            if error != nil {
                print(error!.description)
                callback(GameError.serverError)
                return
            }
            let dataAsDict = data as! [String:Any]
            if let appError = dataAsDict["error"] {
                let errorString = appError as! String
                callback(GameError(rawValue: errorString))
            } else {
                callback(nil)
            }
        })
    }
    
    func nextGameState(callback: @escaping (GameError?) -> ()) {
        self.point.sendMessage(command: "nextGameState", payLoad: nil, callback: {(data, error) in
            if error != nil {
                print(error!)
                callback(GameError.serverError)
                return
            }
            let dataAsDict = data as! [String:Any]
            if dataAsDict.isEmpty {
                callback(nil)
            } else {
                let appError = dataAsDict["error"] as! String
                callback(GameError(rawValue: appError))
            }
        })
    }
    
    private func constructPlayer(playerJson: JSON) -> Player {
        let name = playerJson["name"] as! String
        let id = playerJson["id"] as! String
        var playerLocation: Location?
        let isLeader = playerJson["leader"] as! Bool
        let isTagged = playerJson["isTagged"] as! Bool
        var team: Team?
        //if let location = playerJson["location"] {
            //playerLocation = Location(dict: location as! [String : String])
        //}
        let player = Player(name: name, id: id, flagHeld: nil, location: playerLocation, leader: isLeader, isTagged: isTagged, team: nil)
        return player
    }
    
    private func constructFlag(flagJson: JSON) -> Flag {
        let id = flagJson["id"] as! String
        let isHeld = flagJson["held"] as! Bool
        let location = flagJson["location"] as? [String : String]
        let flagLocation: Location? = Location(dict: location)
        let flag = Flag(id: id, held: isHeld, location: flagLocation)
        return flag
    }
    
    private func constructTeam(teamJson: JSON, players: [Player], flags: [Flag]) -> Team {
        var idsAndPlayers = [String : Player]()
        var idsAndFlags = [String : Flag]()
        for player in players {
            idsAndPlayers[player.id] = player
        }
        for flag in flags {
            idsAndFlags[flag.id] = flag
        }
        let name = teamJson["name"] as! String
        let id = teamJson["id"] as! Int
        let team = Team(name: name, id: id)
        let playerIds = teamJson["players"] as! [String]
        let flagIds = teamJson["flags"] as! [String]
        for playerId in playerIds {
            if let playerToAdd = idsAndPlayers[playerId] {
                team.add(player: playerToAdd)
            }
        }
        for flagId in flagIds {
            if let flagToAdd = idsAndFlags[flagId] {
                team.add(flag: flagToAdd)
            }
        }
        return team
    }
}



extension Location {
    init?(dict: [String:String]?) {
        let latitude = dict?["latitude"]
        let longitude = dict?["longitude"]
        if latitude == nil || longitude == nil {
            return nil
        }
        self.init(latitude: Double(latitude!)!, longitude: Double(longitude!)!)
    }
}

extension GameBoundary {
    init?(json: JSON?) {
        if json == nil {
            return nil
        }
        let rawLocation = json!["center"] as? [String : String]
        let rawDirection = json!["direction"] as! String
        let teamSides = json!["sides"] as? [String : String]
        if rawLocation == nil || rawDirection == nil || teamSides == nil {
            return nil
        }
        let location = Location(dict: rawLocation)
        let direction = BoundaryDirection(rawValue: rawDirection)
        self.init(location: location!, direction: direction!, teamSides: teamSides!)
    }
}





