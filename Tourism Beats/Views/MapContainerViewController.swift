import MapKit
import UIKit

// MARK: - MapContainerViewController

/// Hosts the map in a view controller so floating SwiftUI controls can
/// extend its safe area, which MapKit uses to place its logo, legal link,
/// and edge effects.
final class MapContainerViewController: UIViewController {
    let mapView = MKMapView()

    override func loadView() {
        self.view = self.mapView
    }
}
