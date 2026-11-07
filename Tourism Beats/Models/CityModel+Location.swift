extension CityModel {
    /// What locates the city within its country, or the country itself: Utah
    /// for Lehi, France for Nancy.
    var regionName: String {
        self.administrativeArea ?? self.country.name
    }

    /// The city as people say it: "Lehi, Utah" or "Nancy, France".
    var displayName: String {
        "\(self.name), \(self.regionName)"
    }

    /// Where the city is, in full: "Utah, United States of America" or "France".
    var locationName: String {
        guard let administrativeArea else { return self.country.name }
        return "\(administrativeArea), \(self.country.name)"
    }

    /// Every name that finds the city besides its own, for simple text filters.
    var alternateSearchNames: [String] {
        self.searchAliases + [self.administrativeArea].compactMap(\.self)
    }
}
