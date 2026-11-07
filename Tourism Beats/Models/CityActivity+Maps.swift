import Foundation

extension CityActivity {
    /// The activity in Google Maps, searched within `city` and its country
    /// so a same-named place elsewhere can't be opened instead.
    func mapsURL(in city: CityModel) -> URL? {
        GoogleMapsLink.searchURL(for: [self.name, self.address, city.name, city.country.name])
    }
}
