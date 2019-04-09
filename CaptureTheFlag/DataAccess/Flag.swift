import CoreLocation

class Flag: Equatable, Moveable, Hashable {
    public var location: Location?
    public var id: String
    public var name: String? = nil
    weak public var heldBy: Player?
    weak public var team: Team?
    private var heldObservers = [GameObserverDeletionKey : (Bool, Player) -> ()]()
    private var locationObservers = [GameObserverDeletionKey : (Location) -> ()]()
    
    init(id: String, held: Bool, location: Location?) {
        self.id = id
        //self.held = held
        self.location = location
    }
    
    var hashValue: Int {
        return self.id.hashValue >> 1 ^ 475 << 1
    }
    
    public func set(location: Location) {
        self.location = location
        for observer in self.locationObservers.values {
            observer(location)
        }
    }
    
    public func set(team: Team) {
        self.team = team
    }
    
    public func setHeld(by player: Player) {
        self.heldBy = player
        for observer in self.heldObservers.values {
            observer(true, player)
        }
    }
    
    public func setDropped() {
        let heldByPlayer = self.heldBy
        self.heldBy = nil
        if heldByPlayer != nil {
            for observer in self.heldObservers.values {
                observer(false, heldByPlayer!)
            }
        }
        
    }
    
    public func observerLocation(observer: @escaping (Location) -> ()) -> GameObserverDeletionKey {
        let key = GameObserverDeletionKey(observerType: FlagObserverType.location)
        self.locationObservers[key] = observer
        return key
    }
    
    public func observerHeld(observer: @escaping (Bool, Player) -> ()) -> GameObserverDeletionKey {
        let key = GameObserverDeletionKey(observerType: FlagObserverType.held)
        self.heldObservers[key] = observer
        return key
    }
    
    public func removeObserver(key: GameObserverDeletionKey) -> Bool {
        switch key.observerType {
        case FlagObserverType.location:
            return self.locationObservers.removeValue(forKey: key) != nil ? true : false
        case FlagObserverType.held:
            return self.heldObservers.removeValue(forKey: key) != nil ? true : false
        default:
            return false
        }
    }
    
    /*public var description: String {
        return "name: \(self.name) location: \(self.location) id: \(self.id) held: \(self.heldBy)"
    }*/
    
    static func == (lhs: Flag, rhs: Flag) -> Bool {
        return lhs.id == rhs.id
    }
    
}

fileprivate struct FlagObserverType {
    static let location = "location"
    static let held = "held"
}
