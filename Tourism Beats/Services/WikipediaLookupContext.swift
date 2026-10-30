import CoreLocation

// MARK: - WikipediaLookupContext

/// Where a looked-up place is, so a Wikipedia article that merely shares its
/// name (Cluj-Napoca's Central Park and New York's) is never mistaken for it.
struct WikipediaLookupContext: Sendable {
    let cityName: String
    let cityLatitude: Double
    let cityLongitude: Double
    /// The place's own location, when the source that found it knows it.
    let placeLatitude: Double?
    let placeLongitude: Double?

    init(city: CityModel, placeLatitude: Double? = nil, placeLongitude: Double? = nil) {
        self.cityName = city.name
        self.cityLatitude = city.coordinate.latitude
        self.cityLongitude = city.coordinate.longitude
        self.placeLatitude = placeLatitude
        self.placeLongitude = placeLongitude
    }

    init(city: CityModel, activity: CityActivity) {
        self.init(city: city, placeLatitude: activity.latitude, placeLongitude: activity.longitude)
    }

    var cityLocation: CLLocation {
        CLLocation(latitude: self.cityLatitude, longitude: self.cityLongitude)
    }

    var placeLocation: CLLocation? {
        guard let placeLatitude, let placeLongitude else { return nil }
        return CLLocation(latitude: placeLatitude, longitude: placeLongitude)
    }

    /// Distinguishes lookups of the same title in different places.
    var cacheKey: String {
        let place = self.placeLocation.map {
            "\(Int(($0.coordinate.latitude * 1_000).rounded()))_\(Int(($0.coordinate.longitude * 1_000).rounded()))"
        } ?? "city"
        return "\(self.cityName)|\(place)".lowercased()
    }
}
