import Foundation
class Player: CustomStringConvertible, Moveable, Hashable, Equatable {
    var name: String?
    let id: String
    weak var flagHeld: Flag?
    weak var team: Team?
    var location: Location?
    var leader = false
    var isTagged = false
    private var pickedUpFlagObservers = [GameObserverDeletionKey:(Bool, Flag?) -> ()]()
    private var taggedObservers = [GameObserverDeletionKey:(Bool, Player?) -> ()]()
    private var locationObservers = [GameObserverDeletionKey:(Location) -> ()]()
    private var leaderObservers = [GameObserverDeletionKey:(Bool) -> ()]()
    
    init(name: String, id: String, flagHeld: Flag?, location: Location?, leader: Bool, isTagged: Bool?, team: Team?) {
        self.name = name
        self.id = id
        self.flagHeld = flagHeld
        self.leader = leader
        self.location = location
        self.team = team
    }
    
    public var description: String {
        return "ID: \(String(self.id)) NAME: \(String(describing: self.name)) FLAGHELD: \(String(describing: self.flagHeld)) LOCATION: \(String(describing: self.location)) LEADER: \(self.leader)"
    }
    
    public var hashValue: Int {
        return self.id.hashValue >> 1 ^ self.id.hashValue << 1
    }
    
    public func set(flag: Flag) {
        self.flagHeld = flag
        for observer in self.pickedUpFlagObservers.values {
            observer(true, flag)
        }
    }
    
    public func dropFlag() {
        let flag = self.flagHeld
        self.flagHeld = nil
        for observer in self.pickedUpFlagObservers.values {
            observer(false, flag)
        }
    }
    
    public func set(location: Location) {
        self.location = location
        for observer in self.locationObservers.values {
            observer(location)
        }
    }
    
    public func set(team: Team) {
        if team.contains(player: self) {
            self.team = team
        }
    }
    
    public func set(tagged: Bool, tagger: Player?) {
        self.isTagged = tagged
        for observer in self.taggedObservers.values {
            observer(tagged, tagger)
        }
    }
    
    public func setLeader(_ setTo: Bool) {
        let original = self.leader
        self.leader = setTo
        if original != self.leader {
            for observer in self.leaderObservers.values {
                observer(setTo)
            }
        }
    }
    
    public func isLeader() -> Bool {
        return self.leader
    }
    
    public func observePickedUpFlag(_ observer: @escaping (Bool, Flag?) -> ()) -> GameObserverDeletionKey {
        let key = GameObserverDeletionKey(observerType: PlayerObserverType.pickedUp)
        self.pickedUpFlagObservers[key] = observer
        return key
    }
    
    public func observeTagged(_ observer: @escaping (Bool, Player?) -> ()) -> GameObserverDeletionKey {
        let key = GameObserverDeletionKey(observerType: PlayerObserverType.tagged)
        self.taggedObservers[key] = observer
        return key
    }
    
    public func observeLocation(_ observer: @escaping (Location) -> ()) -> GameObserverDeletionKey {
        let key = GameObserverDeletionKey(observerType: PlayerObserverType.location)
        self.locationObservers[key] = observer
        return key
    }
    
    public func observerMadeLeader(_ observer: @escaping (Bool) -> ()) -> GameObserverDeletionKey {
        let key = GameObserverDeletionKey(observerType: PlayerObserverType.leader)
        self.leaderObservers[key] = observer
        return key
    }
    
    public func removerObserver(key: GameObserverDeletionKey) -> Bool {
        switch key.observerType {
        case PlayerObserverType.pickedUp:
            return self.pickedUpFlagObservers.removeValue(forKey: key) != nil ? true : false
        case PlayerObserverType.tagged:
            return self.taggedObservers.removeValue(forKey: key) != nil ? true : false
        case PlayerObserverType.location:
            return self.locationObservers.removeValue(forKey: key) != nil ? true : false
        case PlayerObserverType.leader:
            return self.leaderObservers.removeValue(forKey: key) != nil ? true : false
        default:
            return false
        }
    }
    
    static func ==(player1: Player, player2: Player) -> Bool {
        return player1.name == player2.name && player1.id == player2.id
    }
}

fileprivate struct PlayerObserverType {
    static let pickedUp = "pickedUp"
    static let tagged = "tagged"
    static let location = "location"
    static let leader = "leader"
}


