import Foundation

// MARK: - TripActivity + Maps

extension TripActivity {
    /// A Google Maps search for where the activity happens, or `nil` when
    /// there is nowhere to point to.
    ///
    /// Places such as sights and restaurants are searched by name within the
    /// trip's city, so suggested activities without an address still resolve.
    /// Other activities need an address of their own.
    var mapsURL: URL? {
        let location = self.location?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        let trip = self.day?.trip

        if self.type.isPlace {
            return GoogleMapsLink.searchURL(for: [self.name, location, trip?.city, trip?.country])
        }

        guard !location.isEmpty else { return nil }
        return GoogleMapsLink.searchURL(for: [location, trip?.city, trip?.country])
    }
}
