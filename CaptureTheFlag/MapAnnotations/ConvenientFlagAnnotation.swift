import Foundation
import MapKit

@objc class ConvenientFlagAnnotation: NSObject, FlagAnnotation {
    var coordinate: CLLocationCoordinate2D
    var title: String?
    var subtitle: String?
    var team: Int?
    weak var flag: Flag?
    
    init(flag: Flag) {
        if let location = flag.location {
            let latitude = location.latitude
            let longitude = location.longitude
            let flagLocation = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
            self.coordinate = flagLocation
        } else {
            self.coordinate = CLLocationCoordinate2D(latitude: -1.0, longitude: -1.0)
        }
        self.title = flag.team?.name
        self.team = flag.team?.id
        self.flag = flag
    }
    
    func updateLocation() {
        if let location = self.flag?.location {
            self.coordinate.latitude = location.latitude
            self.coordinate.longitude = location.longitude
        }
    }
}
