import CoreLocation

struct CityModel: Identifiable, Equatable, Hashable, Sendable {
    let id: String
    let name: String
    let country: CountryModel
    let imageURL: URL
    let coordinate: CLLocationCoordinate2D
    let timeZoneIdentifier: String
    let featuredHeroEligibleOverride: Bool?
    /// Other names people search for the city by, such as its region or
    /// island ("Kashmir" for Srinagar, "Santorini" for Fira).
    let searchAliases: [String]

    init(
        id: String,
        name: String,
        country: CountryModel,
        imageURL: URL,
        coordinate: CLLocationCoordinate2D,
        timeZoneIdentifier: String,
        featuredHeroEligibleOverride: Bool? = nil,
        searchAliases: [String] = []
    ) {
        self.id = id
        self.name = name
        self.country = country
        self.imageURL = imageURL
        self.coordinate = coordinate
        self.timeZoneIdentifier = timeZoneIdentifier
        self.featuredHeroEligibleOverride = featuredHeroEligibleOverride
        self.searchAliases = searchAliases
    }

    var timeZone: TimeZone {
        TimeZone(identifier: self.timeZoneIdentifier) ?? .current
    }

    static func == (lhs: CityModel, rhs: CityModel) -> Bool { lhs.id == rhs.id }
    func hash(into hasher: inout Hasher) { hasher.combine(self.id) }
}
