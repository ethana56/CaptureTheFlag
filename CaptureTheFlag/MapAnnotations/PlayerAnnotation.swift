import Foundation
import MapKit
protocol PlayerAnnotation: MKAnnotation  {
    var team: Int? {get set}
    var tagged: Bool {get set}
}
