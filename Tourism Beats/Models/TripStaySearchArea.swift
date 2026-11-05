import CoreLocation

// MARK: - TripStaySearchArea

/// The city a stay is searched in. Catalog cities bring their centre, so
/// results stay local; other cities are searched by name.
struct TripStaySearchArea: Equatable, Sendable {
    let cityName: String
    let countryName: String
    var center: CLLocationCoordinate2D?

    /// The city and country as one phrase, such as "Lisbon, Portugal".
    var placeName: String {
        [self.cityName, self.countryName].filter { !$0.isEmpty }.joined(separator: ", ")
    }

    static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.cityName == rhs.cityName
            && lhs.countryName == rhs.countryName
            && lhs.center?.latitude == rhs.center?.latitude
            && lhs.center?.longitude == rhs.center?.longitude
    }
}
