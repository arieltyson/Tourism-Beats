import MapKit

// MARK: - TripStaySearchService

/// Searches Apple Maps for hotels in a trip's city.
struct TripStaySearchService: TripStaySearching {
    /// How far across the city's centre a catalog city's search reaches.
    static let searchSpan: CLLocationDistance = 30_000
    /// What an empty query looks for.
    static let browseQuery = String(localized: "Hotels")

    func stays(matching query: String, in area: TripStaySearchArea) async throws -> [TripStay] {
        let request = MKLocalSearch.Request()
        let terms = query.isEmpty ? Self.browseQuery : query
        if let center = area.center {
            request.naturalLanguageQuery = terms
            request.region = MKCoordinateRegion(
                center: center,
                latitudinalMeters: Self.searchSpan,
                longitudinalMeters: Self.searchSpan
            )
        } else {
            request.naturalLanguageQuery = "\(terms), \(area.placeName)"
        }
        request.resultTypes = .pointOfInterest
        request.pointOfInterestFilter = MKPointOfInterestFilter(including: [.hotel])

        let response: MKLocalSearch.Response
        do {
            response = try await MKLocalSearch(request: request).start()
        } catch let error as MKError where error.code == .placemarkNotFound {
            return []
        }

        var seen = Set<String>()
        return response.mapItems.compactMap { item -> TripStay? in
            guard let name = item.name, !name.isEmpty else { return nil }
            let coordinate = item.location.coordinate
            let stay = TripStay(
                name: name,
                address: MapKitAddressFormatter.displayAddress(
                    item.address?.shortAddress ?? item.address?.fullAddress
                ),
                latitude: coordinate.latitude,
                longitude: coordinate.longitude
            )
            return seen.insert(stay.id).inserted ? stay : nil
        }
    }
}
