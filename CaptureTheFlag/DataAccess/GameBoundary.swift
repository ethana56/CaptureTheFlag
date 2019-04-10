
import Foundation
struct GameBoundary {
    let location: Location
    let direction: BoundaryDirection
    let teamSides: [String : String]
    init(location: Location, direction: BoundaryDirection, teamSides: [String : String]) {
        self.location = location
        self.direction = direction
        self.teamSides = teamSides
    }
}
