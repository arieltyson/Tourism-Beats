import Foundation
import Testing
@testable import Tourism_Beats

// MARK: - CityActivityMapsTests

struct CityActivityMapsTests {
    private static func query(of url: URL?) -> String? {
        url.flatMap { URLComponents(url: $0, resolvingAgainstBaseURL: false) }?
            .queryItems?
            .first { $0.name == "query" }?
            .value
    }

    /// The search names the city and country, so a same-named place in
    /// another city can't be opened instead.
    @Test func searchesWithinTheCityAndCountry() {
        let activity = TripPlanningFixtures.activity("Royal Botanic Gardens")
        let url = activity.mapsURL(in: TripPlanningFixtures.portOfSpain)

        #expect(url?.host() == "www.google.com")
        #expect(
            Self.query(of: url)
                == "Royal Botanic Gardens, Royal Botanic Gardens Road, Port of Spain, Trinidad and Tobago"
        )
    }
}
