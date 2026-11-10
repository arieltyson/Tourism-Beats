import Foundation

// MARK: - GastroCity

/// A place in the ranking of the world's gastronomic capitals, naming a
/// catalog city by its name and country so its photo and page come from
/// the catalog.
struct GastroCity: Identifiable, Hashable, Sendable {
    /// Its place in the ranking, from 1.
    let rank: Int
    let name: String
    /// The ISO 3166-1 alpha-2 code of the city's country.
    let countryCode: String
    let distinction: GastroDistinction

    var id: Int { self.rank }
}

// MARK: - FeaturedGastroCity

/// A ranked gastronomic capital joined to the catalog city it opens.
struct FeaturedGastroCity: Identifiable, Hashable, Sendable {
    let ranking: GastroCity
    let city: CityModel

    var id: Int { self.ranking.id }

    var accessibilityLabel: String {
        String(
            localized: "Number \(self.ranking.rank), \(self.city.name), \(self.city.country.name). \(self.ranking.distinction.text)"
        )
    }
}
