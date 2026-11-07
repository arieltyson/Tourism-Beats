import CoreLocation

struct CityModel: Identifiable, Equatable, Hashable, Sendable {
    let id: String
    let name: String
    let country: CountryModel
    /// The state, province, or territory, where people place the city by it
    /// ("Lehi, Utah"). `nil` where the country alone is what people say.
    let administrativeArea: String?
    let imageURL: URL
    let coordinate: CLLocationCoordinate2D
    let timeZoneIdentifier: String
    let featuredHeroEligibleOverride: Bool?
    /// Other names people search for the city by, such as its region or
    /// island ("Kashmir" for Srinagar, "Santorini" for Fira).
    let searchAliases: [String]
    /// Facts worth telling that a Wikipedia introduction wouldn't reach, such
    /// as the origin of quiche for Nancy. They join the facts looked up live.
    let curatedFunFacts: [CityFunFact]
    /// The one Wikipedia article to take facts from, for a city whose name
    /// alone finds the wrong one (Chail, Himachal Pradesh, not Uttar Pradesh)
    /// or that has no article of its own (Orimasvaru, told by its atoll's).
    let wikipediaTitle: String?

    init(
        id: String,
        name: String,
        country: CountryModel,
        administrativeArea: String? = nil,
        imageURL: URL,
        coordinate: CLLocationCoordinate2D,
        timeZoneIdentifier: String,
        featuredHeroEligibleOverride: Bool? = nil,
        searchAliases: [String] = [],
        curatedFunFacts: [CityFunFact] = [],
        wikipediaTitle: String? = nil
    ) {
        self.id = id
        self.name = name
        self.country = country
        self.administrativeArea = administrativeArea
        self.imageURL = imageURL
        self.coordinate = coordinate
        self.timeZoneIdentifier = timeZoneIdentifier
        self.featuredHeroEligibleOverride = featuredHeroEligibleOverride
        self.searchAliases = searchAliases
        self.curatedFunFacts = curatedFunFacts
        self.wikipediaTitle = wikipediaTitle
    }

    var timeZone: TimeZone {
        TimeZone(identifier: self.timeZoneIdentifier) ?? .current
    }

    static func == (lhs: CityModel, rhs: CityModel) -> Bool { lhs.id == rhs.id }
    func hash(into hasher: inout Hasher) { hasher.combine(self.id) }
}
