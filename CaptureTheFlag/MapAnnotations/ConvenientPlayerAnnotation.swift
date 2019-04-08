import MapKit
import Foundation

@objc class ConvenientPlayerAnnotaton: NSObject, PlayerAnnotation {
    var coordinate: CLLocationCoordinate2D
    var title: String?
    var subtitle: String?
    var team: Int?
    var tagged: Bool
    weak var player: Player?
    init(player: Player) {
        if let location = player.location {
            let latitude = location.latitude
            let longitude = location.longitude
            let playerLocation = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
            self.coordinate = playerLocation
        } else {
            self.coordinate = CLLocationCoordinate2D(latitude: -1.0, longitude: -1.0)
        }
        self.title = player.name
        self.subtitle = player.team?.name
        self.team = player.team?.id
        self.player = player
        self.tagged = player.isTagged
        super.init()
    }
    
    func updateLocation() {
        if let location = self.player?.location {
            self.coordinate.latitude = location.latitude
            self.coordinate.longitude = location.longitude
        }
    }
}
