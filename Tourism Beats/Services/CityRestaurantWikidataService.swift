import CoreLocation
import Foundation
import OSLog

// MARK: - CityRestaurantWikidataService

/// Pillar 2: Queries the free Wikidata SPARQL endpoint for award-winning
/// restaurants (Michelin stars, Bib Gourmand, James Beard, etc.) near a city.
enum CityRestaurantWikidataService {
    private static let logger = Logger(
        subsystem: Bundle.main.bundleIdentifier ?? "TourismBeats",
        category: "CityRestaurantWikidata"
    )

    static func fetchAwards(
        for city: CityModel,
        session: URLSession
    ) async -> [CityRestaurantAPIModels.WikidataRestaurantMatch] {
        let sparqlQuery = self.sparqlQuery(
            latitude: city.coordinate.latitude,
            longitude: city.coordinate.longitude
        )

        var components = URLComponents(string: "https://query.wikidata.org/sparql")
        components?.queryItems = [
            URLQueryItem(name: "query", value: sparqlQuery),
            URLQueryItem(name: "format", value: "json")
        ]

        guard let url = components?.url else { return [] }

        do {
            var request = URLRequest(url: url)
            request.cachePolicy = .useProtocolCachePolicy
            request.timeoutInterval = 15
            request.setValue(
                "TourismBeats/1.0 (\(Bundle.main.bundleIdentifier ?? "city-restaurants"))",
                forHTTPHeaderField: "User-Agent"
            )

            let (data, response) = try await session.data(for: request)

            guard let http = response as? HTTPURLResponse,
                  200 ..< 300 ~= http.statusCode
            else {
                return []
            }

            let decoder = JSONDecoder()
            let sparqlResponse = try decoder.decode(
                CityRestaurantAPIModels.WikidataSPARQLResponse.self,
                from: data
            )
            return self.processBindings(sparqlResponse.results.bindings)
        } catch {
            self.logger.info(
                "Wikidata enrichment unavailable: \(error.localizedDescription, privacy: .public)"
            )
            return []
        }
    }

    static func enrichCandidates(
        _ candidates: [CityRestaurantCandidate],
        with wikidataMatches: [CityRestaurantAPIModels.WikidataRestaurantMatch]
    ) -> [CityRestaurantCandidate] {
        candidates.map { candidate in
            guard let candidateLat = candidate.latitude,
                  let candidateLon = candidate.longitude
            else {
                return candidate
            }

            let normalizedName = candidate.name.folding(
                options: [.caseInsensitive, .diacriticInsensitive],
                locale: .current
            )

            let match = wikidataMatches.first { wikiMatch in
                let normalizedWikiName = wikiMatch.name.folding(
                    options: [.caseInsensitive, .diacriticInsensitive],
                    locale: .current
                )

                let nameMatches = normalizedName == normalizedWikiName
                    || normalizedName.localizedStandardContains(normalizedWikiName)
                    || normalizedWikiName.localizedStandardContains(normalizedName)

                guard nameMatches else { return false }

                let distance = CLLocation(latitude: candidateLat, longitude: candidateLon)
                    .distance(from: CLLocation(
                        latitude: wikiMatch.latitude,
                        longitude: wikiMatch.longitude
                    ))
                return distance < 500
            }

            guard let match else { return candidate }

            var enriched = candidate
            enriched.wikidataAwardCount = match.awardCount
            enriched.isMichelinRecognized = match.isMichelinRecognized
            return enriched
        }
    }
}

// MARK: - SPARQL Query & Processing

extension CityRestaurantWikidataService {
    private static func sparqlQuery(
        latitude: Double,
        longitude: Double
    ) -> String {
        """
        SELECT ?restaurantLabel ?lat ?lon
               (GROUP_CONCAT(DISTINCT ?awardLabel; SEPARATOR="|") AS ?awardLabel)
               (SAMPLE(?stars) AS ?michelinStars)
        WHERE {
          SERVICE wikibase:around {
            ?restaurant wdt:P625 ?location .
            bd:serviceParam wikibase:center "Point(\(longitude) \(latitude))"^^geo:wktLiteral .
            bd:serviceParam wikibase:radius "15" .
          }
          ?restaurant wdt:P625 ?location .
          ?restaurant wdt:P31/wdt:P279* wd:Q11707 .
          BIND(geof:latitude(?location) AS ?lat)
          BIND(geof:longitude(?location) AS ?lon)
          OPTIONAL {
            ?restaurant wdt:P166 ?award .
            ?award rdfs:label ?awardLabel .
            FILTER(LANG(?awardLabel) = "en")
          }
          OPTIONAL { ?restaurant wdt:P1132 ?stars . }
          SERVICE wikibase:label { bd:serviceParam wikibase:language "en,fr,de,es,ja,zh" . }
        }
        GROUP BY ?restaurantLabel ?lat ?lon
        LIMIT 50
        """
    }

    private static func processBindings(
        _ bindings: [CityRestaurantAPIModels.WikidataBinding]
    ) -> [CityRestaurantAPIModels.WikidataRestaurantMatch] {
        bindings.compactMap { binding in
            guard let name = binding.restaurantLabel?.value,
                  let latStr = binding.lat?.value,
                  let lonStr = binding.lon?.value,
                  let latitude = Double(latStr),
                  let longitude = Double(lonStr)
            else {
                return nil
            }

            let awards = binding.awardLabel?.value
                .split(separator: "|")
                .map(String.init)
                ?? []

            let hasMichelin = binding.michelinStars?.value != nil
                || awards.contains { award in
                    let lower = award.lowercased()
                    return lower.contains("michelin")
                        || lower.contains("bib gourmand")
                }

            return CityRestaurantAPIModels.WikidataRestaurantMatch(
                name: name,
                latitude: latitude,
                longitude: longitude,
                awardCount: awards.count,
                isMichelinRecognized: hasMichelin
            )
        }
    }
}
