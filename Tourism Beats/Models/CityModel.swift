import CoreLocation

struct CityModel: Identifiable, Equatable, Hashable, Sendable {
    let id: String
    let name: String
    let country: CountryModel
    let imageURL: URL
    let coordinate: CLLocationCoordinate2D
    let timeZoneIdentifier: String
    let featuredHeroEligibleOverride: Bool?

    init(
        id: String,
        name: String,
        country: CountryModel,
        imageURL: URL,
        coordinate: CLLocationCoordinate2D,
        timeZoneIdentifier: String,
        featuredHeroEligibleOverride: Bool? = nil
    ) {
        self.id = id
        self.name = name
        self.country = country
        self.imageURL = imageURL
        self.coordinate = coordinate
        self.timeZoneIdentifier = timeZoneIdentifier
        self.featuredHeroEligibleOverride = featuredHeroEligibleOverride
    }

    var timeZone: TimeZone {
        TimeZone(identifier: self.timeZoneIdentifier) ?? .current
    }

    static func == (lhs: CityModel, rhs: CityModel) -> Bool { lhs.id == rhs.id }
    func hash(into hasher: inout Hasher) { hasher.combine(self.id) }
}
