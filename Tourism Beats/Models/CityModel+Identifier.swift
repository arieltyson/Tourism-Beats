extension CityModel {
    /// The stable identifier for a catalog city, such as "Lehi-US".
    ///
    /// A city whose name another city in its country shares also carries its
    /// state or province, as in "Portland-Maine-US" and "Portland-Oregon-US".
    /// The identifier names each city's cached activities, restaurants, and
    /// facts, so two cities must never share one. Every other city keeps its
    /// short form, and with it everything already cached for it.
    static func identifier(
        name: String,
        administrativeArea: String?,
        countryCode: String,
        sharesName: Bool
    ) -> String {
        guard sharesName, let administrativeArea else { return "\(name)-\(countryCode)" }
        return "\(name)-\(administrativeArea)-\(countryCode)"
    }
}
