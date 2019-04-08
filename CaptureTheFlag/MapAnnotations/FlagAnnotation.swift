import Foundation
import MapKit
protocol FlagAnnotation: MKAnnotation {
    var team: Int? {get set}
}
