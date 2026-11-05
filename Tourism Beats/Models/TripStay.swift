import CoreLocation
import Foundation

// MARK: - TripStay

/// Where a traveller is staying, so a trip's suggestions can start nearby.
struct TripStay: Identifiable, Hashable, Sendable {
    let name: String
    let address: String?
    let latitude: Double
    let longitude: Double

    var id: String { "\(self.name)|\(self.latitude)|\(self.longitude)" }

    var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: self.latitude, longitude: self.longitude)
    }
}
