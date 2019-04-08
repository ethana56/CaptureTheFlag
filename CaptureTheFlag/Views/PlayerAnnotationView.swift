
import UIKit
import MapKit

class PlayerAnnotationView: MKMarkerAnnotationView {
    private static let teamColor = [
        1 : UIColor.red,
        2 : UIColor.blue,
        nil : UIColor.orange
    ]
    init(annotation: PlayerAnnotation, reuseIdentifier: String) {
        super.init(annotation: annotation, reuseIdentifier: reuseIdentifier)
        super.markerTintColor = PlayerAnnotationView.teamColor[annotation.team]
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    func update(annotation: PlayerAnnotation) {
        super.markerTintColor = PlayerAnnotationView.teamColor[annotation.team]
        if annotation.tagged {
            super.alpha = 0.4
        } else {
            super.alpha = 1.0
        }
    }
}
