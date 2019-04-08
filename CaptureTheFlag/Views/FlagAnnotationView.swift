import MapKit

class FlagAnnotationView: MKAnnotationView {
    private static let flagImage = [
        1 : UIImage(named: "RedFlag"),
        2 : UIImage(named: "BlueFlag"),
        nil : UIImage(named: "OrangeFlag")
    ]
    init(annotation: FlagAnnotation, reuseIdentifier: String) {
        super.init(annotation: annotation, reuseIdentifier: reuseIdentifier)
        if let image = FlagAnnotationView.flagImage[annotation.team] {
            super.image = image
        } else {
            
        }
        super.centerOffset = CGPoint(x:22,y: -20)
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    func update(annotation: FlagAnnotation) {
        if let image = FlagAnnotationView.flagImage[annotation.team] {
            self.image = image
        } else {
            
        }
    }
    

}
