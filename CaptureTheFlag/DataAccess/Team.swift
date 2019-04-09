import Foundation
class Team: CustomStringConvertible, Hashable, Equatable {
    static func == (lhs: Team, rhs: Team) -> Bool {
        return lhs.name == rhs.name && lhs.id == rhs.id
    }
    let name: String
    var players = Set<Player>()
    var flags = Set<Flag>()
    var id: Int
    private var playerAddedRemovedObservers = [GameObserverDeletionKey : (Player, Bool) -> ()]()
    private var flagAddedRemovedObservers = [GameObserverDeletionKey : (Flag, Bool) -> ()]()
    
    public init(name: String, id: Int) {
        self.name = name
        self.id = id
    }
    
    public var hashValue: Int {
        return self.name.hashValue >> 1 ^ 53487456859
    }
    
    public var description: String {
        return "Players: \(self.players)"
    }
    
    public func add(player: Player) {
        self.players.insert(player)
        player.set(team: self)
        for observer in self.playerAddedRemovedObservers.values {
            observer(player, true)
        }
    }
    
    public func remove(player: Player) {
        if let removedPlayer = self.players.remove(player) {
            for observer in playerAddedRemovedObservers.values {
                observer(removedPlayer, false)
            }
        }
    }
    
    public func remove(flag: Flag) {
        if let removedFlag = self.flags.remove(flag) {
            for observer in self.flagAddedRemovedObservers.values {
                observer(flag, false)
            }
        }
    }
    
    public func add(flag: Flag) {
        self.flags.insert(flag)
        flag.set(team: self)
        for observer in self.flagAddedRemovedObservers.values {
            observer(flag, true)
        }
    }
    
    public func observerPlayerAdded(observer: @escaping (Player, Bool) -> ()) -> GameObserverDeletionKey {
        let key = GameObserverDeletionKey(observerType: TeamObserverType.playerAdded)
        self.playerAddedRemovedObservers[key] = observer
        return key
    }
    
    public func observeFlagAdded(observer: @escaping (Flag, Bool) -> ()) -> GameObserverDeletionKey {
        let key = GameObserverDeletionKey(observerType: TeamObserverType.flagAdded)
        self.flagAddedRemovedObservers[key] = observer
        return key
        
    }
    
    public func removeObserver(key: GameObserverDeletionKey) -> Bool {
        switch key.observerType {
        case TeamObserverType.playerAdded:
            return self.playerAddedRemovedObservers.removeValue(forKey: key) != nil
        case TeamObserverType.flagAdded:
            return self.flagAddedRemovedObservers.removeValue(forKey: key) != nil
        default:
            return false
        }
    }
    
    public func contains(player: Player) -> Bool {
        return self.players.contains(player)
    }
    
    public func contains(flag: Flag) -> Bool {
        return self.flags.contains(flag)
    }
}

struct TeamObserverType {
    static let playerAdded = "playerAdded"
    static let flagAdded = "flagAdded"
}


