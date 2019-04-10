import UIKit
import MapKit
import CoreLocation
class MapFlagPlacementViewController: CaptureTheFlagViewController, UIGestureRecognizerDelegate, MKMapViewDelegate, CLLocationManagerDelegate {
    @IBOutlet weak var startGameButton: UIButton!
    @IBOutlet weak var map: MKMapView!
    var mapGestureRecognizer: UITapGestureRecognizer?
    
    @IBOutlet weak var notificationText: UILabel!
    var players = Set<Player>()
    var teams = Set<Team>()
    var flags = Set<Flag>()
    weak var userPlayer: Player?
    
    var playerObserverKeys = [Player:[GameObserverDeletionKey]]()
    var flagObserverKeys = [Flag:[GameObserverDeletionKey]]()
    var teamObserverKeys = [Team: [GameObserverDeletionKey]]()
    
    var playerAnnotations = [Player:ConvenientPlayerAnnotaton]()
    var flagAnnotations = [Flag:ConvenientFlagAnnotation]()
    
    var listenerKeys = [GameListenerKey]()
    var gameState: Int!
    
    var tapMode = TapMode.flag
    var boundary: GameBoundary?
    let locationManager = CLLocationManager()
    
    var winningTeam: Team?
    
    enum TapMode {
        case flag
        case boundary
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.setUpLocation()
        self.map.delegate = self
        self.navigationItem.hidesBackButton = true
        
        notificationText.alpha = 0
        if self.players.count == 0 {
            self.serverAccess?.getCurrentGameState(callback: {(playersFlagsTeams, error) in
                if error != nil {
                    self.handleError(error!)
                } else {
                    let players = playersFlagsTeams?.0
                    let flags = playersFlagsTeams?.1
                    let teams = playersFlagsTeams?.2
                    let name = playersFlagsTeams?.4
                    self.gameState = playersFlagsTeams?.5
                    let userPlayerId = playersFlagsTeams?.6
                    self.updateData(players: players!, flags: flags!, teams: teams!)
                    for player in self.players {
                        if player.id == userPlayerId {
                            self.userPlayer = player
                            break
                        }
                    }
                    if name != nil {
                        self.navigationItem.title = name!
                    }
                    self.reloadMap()
                    self.createListeners()
                    self.addPlayerObservers()
                    self.addFlagObservers()
                    self.addTeamObservers()
                }
            })
        }
        self.mapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(addItemToMap(gestureRecognizer:)))
        self.map?.addGestureRecognizer(self.mapGestureRecognizer!)
        
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        self.removeAllObservers()
        self.removeAllData()
        
    }
    
    private func removeAllData() {
        self.players.removeAll()
        self.flags.removeAll()
        self.teams.removeAll()
        self.playerObserverKeys.removeAll()
        self.flagObserverKeys.removeAll()
        self.teamObserverKeys.removeAll()
        self.playerAnnotations.removeAll()
        self.flagAnnotations.removeAll()
        self.boundary = nil
        self.userPlayer = nil
    }
    
    @objc func addItemToMap(gestureRecognizer: UITapGestureRecognizer) {
        let touchpoint = gestureRecognizer.location(in: self.map)
        let locationTapped = self.map?.convert(touchpoint, toCoordinateFrom: self.map)
        if self.tapMode == TapMode.flag {
            self.serverAccess?.createFlag(latitude: String(locationTapped!.latitude), longitude:
                String(locationTapped!.longitude), callback: {(error) in
                if error != nil {
                    self.animateNotification(text: self.translateError(error: error!))
                }
            })
        } else if self.tapMode == TapMode.boundary {
            self.serverAccess?.createGameBoundary(location: Location(latitude: Double(locationTapped!.latitude), longitude: Double(locationTapped!.longitude)), direction: BoundaryDirection.verical, callback: {(error) in
                
            })
        }
        
    }
    
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        if let flagAnnotation = annotation as? FlagAnnotation {
            var annotationView = self.map?.dequeueReusableAnnotationView(withIdentifier: "flag") as? FlagAnnotationView
            if annotationView == nil {
                annotationView = FlagAnnotationView(annotation: flagAnnotation, reuseIdentifier: "flag")
            } else {
                annotationView!.update(annotation: flagAnnotation)
            }
            
            return annotationView
        }
        if let playerAnnotation = annotation as? ConvenientPlayerAnnotaton {
            var annotationView = self.map?.dequeueReusableAnnotationView(withIdentifier: "player") as? PlayerAnnotationView
            if annotationView == nil {
                annotationView = PlayerAnnotationView(annotation: playerAnnotation, reuseIdentifier: "player")
            } else {
                annotationView!.update(annotation: playerAnnotation)
            }
            return annotationView
        }
        return nil
    }
    
    func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
        if let overlay = overlay as? MKCircle {
            let circleRenderer = MKCircleRenderer(circle: overlay)
            circleRenderer.fillColor = UIColor.blue
            circleRenderer.alpha = 0.15
            return circleRenderer
        }
        if let overlay = overlay as? MKPolyline {
            let lineRenderer = MKPolylineRenderer(polyline: overlay)
            return lineRenderer
        }
        return MKCircleRenderer(overlay: overlay)
        
    }
    func mapView(_ mapView: MKMapView, didSelect view: MKAnnotationView) {
        if let playerAnnotation = view.annotation! as? ConvenientPlayerAnnotaton {
            if self.gameState == 1 && self.userPlayer?.leader != nil {
                self.serverAccess?.makeLeader(player: playerAnnotation.player!, callback: {(error) in
                    if error != nil {
                        self.animateNotification(text: self.translateError(error: error!))
                    }
                })
                return
            }
            self.serverAccess?.tagPlayer(player: playerAnnotation.player!, callback: {(error) in
                if error != nil {
                    print(error!.rawValue)
                    self.animateNotification(text: self.translateError(error: error!))
                }
            })
        } else if let flagAnnotation = view.annotation! as? ConvenientFlagAnnotation {
            self.serverAccess?.pickUpFlag(flag: flagAnnotation.flag!, callback: {(error) in
                if error != nil {
                    self.animateNotification(text: self.translateError(error: error!))
                }
            })
        }
    }
    
    private func updateData(players: [Player], flags: [Flag], teams: [Team]) {
        self.players.removeAll()
        self.flags.removeAll()
        self.teams.removeAll()
        for player in players {
           self.players.insert(player)
        }
        for flag in flags {
            self.flags.insert(flag)
        }
        for team in teams {
            self.teams.insert(team)
        }
    }
    
    private func reloadMap() {
        for player in self.players {
            if let playerAnnotation = self.playerAnnotations[player] {
                self.map.removeAnnotation(playerAnnotation)
                self.playerAnnotations.removeValue(forKey: player)
            }
            self.addToMap(player)
        }
        for flag in self.flags {
            if let flagAnnotation = self.flagAnnotations[flag] {
                self.map.removeAnnotation(flagAnnotation)
                self.flagAnnotations.removeValue(forKey: flag)
            }
            self.addToMap(flag)
        }
    }
    
    
    
    private func addToMap(_ player: Player) {
        if let playerLocation = player.location {
            let annotation = ConvenientPlayerAnnotaton(player: player)
            self.playerAnnotations[player] = annotation
            self.map?.addAnnotation(annotation)
        }
    }
    
    private func addToMap(_ flag: Flag) {
        if flag.heldBy != nil {
            return
        }
        let annotation = ConvenientFlagAnnotation(flag: flag)
        self.flagAnnotations[flag] = annotation
        self.map?.addAnnotation(annotation)
    }
    
    
    @IBAction func startGame(_ sender: Any) {
        self.serverAccess?.nextGameState(callback: {(error) in
            if error != nil {
                self.handleError(error!)
            }
        })
    }
    
    private func addPlayerObservers() {
        for player in self.players {
            if self.playerObserverKeys[player] == nil {
                self.playerObserverKeys[player] = []
            }
          self.playerObserverKeys[player]!.append(player.observeLocation({(location) in
                if let annotation = self.playerAnnotations[player] {
                    annotation.updateLocation()
                    self.map?.removeAnnotation(annotation)
                    self.map?.addAnnotation(annotation)
                } else {
                    self.addToMap(player)
                }
            }))
            
           self.playerObserverKeys[player]!.append(player.observeTagged({(tagged, tagger) in
                if tagged {
                    if let annotation = self.playerAnnotations[player] {
                        annotation.tagged = true
                        self.map?.removeAnnotation(annotation)
                        self.map?.addAnnotation(annotation)
                    }
                    self.animateNotification(text: "You have been tagged by \(String(describing: tagger?.name))")
                } else {
                    if let annotation = self.playerAnnotations[player] {
                        annotation.tagged = false
                        self.map?.removeAnnotation(annotation)
                        self.map?.addAnnotation(annotation)
                    }
                }
            }))
            
           self.playerObserverKeys[player]!.append(player.observePickedUpFlag({(pickedUp, flag) in
                if pickedUp && flag != nil {
                    self.map.removeAnnotation(self.flagAnnotations[flag!]!)
                } else if !pickedUp && flag != nil {
                    if let annotation = self.flagAnnotations[flag!] {
                        annotation.updateLocation()
                        self.map.addAnnotation(annotation)
                    }
                }
            }))
            
           self.playerObserverKeys[player]!.append(player.observerMadeLeader({(madeLeader) in
                self.animateNotification(text: "You were made a leader")
            }))
        }
    }
    
    private func addFlagObservers() {
        for flag in self.flags {
            if self.flagObserverKeys[flag] == nil {
                self.flagObserverKeys[flag] = []
            }
           self.flagObserverKeys[flag]!.append(flag.observerLocation(observer: {(location) in
                if let annotation = self.flagAnnotations[flag] {
                    annotation.updateLocation()
                    self.map?.removeAnnotation(annotation)
                    self.map?.addAnnotation(annotation)
                }
            }))
        }
    }
    
    private func addTeamObservers() {
        for team in self.teams {
            if self.teamObserverKeys[team] == nil {
                self.teamObserverKeys[team] = []
            }
           self.teamObserverKeys[team]!.append(team.observerPlayerAdded(observer: {(player, added) in
                if let annotation = self.playerAnnotations[player] {
                    annotation.team = team.id
                    self.map?.removeAnnotation(annotation)
                    self.map.addAnnotation(annotation)
                }
            }))
           self.teamObserverKeys[team]!.append(team.observeFlagAdded(observer: {(flag, added) in
                if let annotation = self.flagAnnotations[flag] {
                    annotation.team = team.id
                    self.map?.removeAnnotation(annotation)
                    self.map?.addAnnotation(annotation)
                }
            }))
        }
    }
    
    private func createListeners() {
        let listenerArray: [GameListenerKey] = [
            (self.serverAccess?.addFlagAddedListener(callback: {(flag) in
                self.flags.insert(flag)
                self.addToMap(flag)
            }))!,
            
            (self.serverAccess?.addGameStateChangedListener(callback: {(gameState) in
                self.map?.removeGestureRecognizer(self.mapGestureRecognizer!)
                self.gameState = gameState
            }))!,
            
            ((self.serverAccess?.addBoundaryAddedListener(callback: {(boundary) in
                self.boundary = boundary
                let gameBounds = MKCircle(center: boundary.location, radius: 4000)
                let polyline = self.createPolyLine(boundary: boundary)
                self.map.add(gameBounds)
                self.map.add(polyline!)
            }))!),
            
            (self.serverAccess?.addGameOverListener(callback: {(winningTeam) in
                self.winningTeam = winningTeam
                
                self.performSegue(withIdentifier: "GameOver", sender: nil)
            }))!
            
        ]
        self.listenerKeys.append(contentsOf: listenerArray)
    }
    
    private func animateNotification(text: String) {
        self.notificationText.alpha = 0
        self.notificationText.text = text
        UIView.animate(withDuration: 1.0, animations: {self.notificationText.alpha = 1}, completion: {(completed) in
            Timer.scheduledTimer(withTimeInterval: 2.0, repeats: false, block: {(timer) in
                 UIView.animate(withDuration: 0.5, animations: {self.notificationText.alpha = 0})
            })
        })
    }
    
    private func removeAllObservers() {
        for player in self.playerObserverKeys.keys {
            for key in self.playerObserverKeys[player]! {
                player.removerObserver(key: key)
            }
            self.playerObserverKeys[player]!.removeAll()
        }
        for flag in self.flagObserverKeys.keys {
            for key in self.flagObserverKeys[flag]! {
                flag.removeObserver(key: key)
            }
            self.flagObserverKeys[flag]!.removeAll()
        }
        
        for team in self.teamObserverKeys.keys {
            for key in self.teamObserverKeys[team]! {
                team.removeObserver(key: key)
            }
            self.teamObserverKeys[team]!.removeAll()
        }
    }
    
    private func createPolyLine(boundary: GameBoundary) -> MKPolyline? {
        if boundary.direction == BoundaryDirection.verical {
            let latitudeBottom = boundary.location.latitude - 4000
            let latitudeTop = boundary.location.latitude + 4000
            let longitude = boundary.location.longitude
            let coord1 = CLLocationCoordinate2D(latitude: latitudeBottom, longitude: longitude)
            let coord2 = CLLocationCoordinate2D(latitude: latitudeTop, longitude: longitude)
            let coords = [coord1, coord2]
            return MKPolyline(coordinates: coords, count: coords.count)
        }
        //Add horizontal later
        return nil
    }
    
    func handleError(_ error: GameError) {
        print(error)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let nextViewController = segue.destination as? GameOverViewController {
            nextViewController.winningTeam = self.winningTeam
        }
    }
    
    @IBAction func printInfo(_ sender: Any) {
        if (self.tapMode == TapMode.flag) {
            self.tapMode = TapMode.boundary
        } else {
            self.tapMode = TapMode.flag
        }
    }
    
    @IBAction func dropFlag(_ sender: Any) {
        self.serverAccess?.dropFlag(callback: {(error) in
            print(error)
        })
    }
    
     public func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        self.serverAccess?.updateLocation(latitude: String(locations.last!.coordinate.latitude), longitude: String(locations.last!.coordinate.longitude))
    }
    
    private func setUpLocation() {
        self.locationManager.delegate = self
        self.locationManager.desiredAccuracy = kCLLocationAccuracyBestForNavigation
        self.locationManager.requestAlwaysAuthorization()
        self.locationManager.startUpdatingLocation()
    }
    
    private func translateError(error: GameError) -> String {
        switch error {
        case .playersNotCloseEnough:
            return "You must be closer to do that"
        case .playerDoesNotHavePermission:
            return "You do not have permission to do that"
        case .playerNotInBounds:
            return "You must be in bounds to do that"
        case .incorrectGameState:
            return "The game is not in the correct mode to do that"
        case .serverError:
            return "There is an error accessing the server"
        default:
            return "Something went wrong"
        }
    }
}

extension MKCircle {
    convenience init(center: Location, radius: Double) {
        let cllocation = CLLocationCoordinate2D(latitude: center.latitude, longitude: center.longitude)
        self.init(center: cllocation, radius: radius)
    }
}
