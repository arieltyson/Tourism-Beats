import CoreLocation
import Foundation
import MapKit
import OSLog

// MARK: - MapKit Search (Multi-Query Cross-Referencing)

extension CityRestaurantService {
    /// Pillar 1: Run multiple natural language queries against MapKit and
    /// track how many independent queries return each restaurant.
    /// Restaurants appearing across multiple queries are demonstrably popular.
    @MainActor
    static func multiQueryMapKitSearch(
        for city: CityModel
    ) async -> [RestaurantModels.MapKitRestaurantResult] {
        let popularityQueries = [
            "restaurants",
            "best restaurants",
            "popular restaurants",
            "top rated restaurants"
        ]

        let foodQualityQueries = [
            "best food \(city.name)",
            "fine dining",
            "authentic local cuisine"
        ]

        var appearanceCounts: [String: Int] = [:]
        var foodQueryCounts: [String: Int] = [:]
        var bestResultByKey: [String: RestaurantModels.MapKitRestaurantResult] = [:]

        let queries = popularityQueries + foodQualityQueries
        let resultsByQuery = await self.concurrentMapKitSearches(for: city, queries: queries)

        // Fold in query order so ties resolve the same way on every load.
        for (index, results) in resultsByQuery.enumerated() {
            self.accumulateResults(
                from: results,
                into: &bestResultByKey,
                appearanceCounts: &appearanceCounts
            )
            guard index >= popularityQueries.count else { continue }

            for result in results {
                let key = self.coordinateKey(
                    latitude: result.latitude,
                    longitude: result.longitude
                )
                foodQueryCounts[key, default: 0] += 1
            }
        }

        return bestResultByKey.values.map { result in
            let key = self.coordinateKey(
                latitude: result.latitude,
                longitude: result.longitude
            )
            return RestaurantModels.MapKitRestaurantResult(
                name: result.name,
                phoneNumber: result.phoneNumber,
                websiteURL: result.websiteURL,
                address: result.address,
                latitude: result.latitude,
                longitude: result.longitude,
                popularityRank: result.popularityRank,
                crossQueryAppearanceCount: appearanceCounts[key, default: 1],
                foodQueryAppearanceCount: foodQueryCounts[key, default: 0],
                mapItemIdentifier: result.mapItemIdentifier
            )
        }
        .sorted { $0.popularityRank < $1.popularityRank }
    }

    /// Runs every query at once and returns each query's results at its index,
    /// so the slowest search sets the pace instead of the sum of all of them.
    @MainActor
    static func concurrentMapKitSearches(
        for city: CityModel,
        queries: [String]
    ) async -> [[RestaurantModels.MapKitRestaurantResult]] {
        await withTaskGroup(of: (Int, [RestaurantModels.MapKitRestaurantResult]).self) { group in
            for (index, query) in queries.enumerated() {
                group.addTask {
                    await (index, self.singleMapKitSearch(for: city, query: query))
                }
            }

            var resultsByQuery = Array(repeating: [RestaurantModels.MapKitRestaurantResult](), count: queries.count)
            for await (index, results) in group {
                resultsByQuery[index] = results
            }
            return resultsByQuery
        }
    }

    @MainActor
    static func accumulateResults(
        from results: [RestaurantModels.MapKitRestaurantResult],
        into bestResultByKey: inout [String: RestaurantModels.MapKitRestaurantResult],
        appearanceCounts: inout [String: Int]
    ) {
        for result in results {
            let key = self.coordinateKey(
                latitude: result.latitude,
                longitude: result.longitude
            )

            appearanceCounts[key, default: 0] += 1

            if let existing = bestResultByKey[key] {
                if result.popularityRank < existing.popularityRank {
                    bestResultByKey[key] = result
                }
            } else {
                bestResultByKey[key] = result
            }
        }
    }

    @MainActor
    static func singleMapKitSearch(
        for city: CityModel,
        query: String
    ) async -> [RestaurantModels.MapKitRestaurantResult] {
        do {
            let request = MKLocalSearch.Request()
            request.naturalLanguageQuery = query
            request.region = MKCoordinateRegion(
                center: city.coordinate,
                latitudinalMeters: 10_000,
                longitudinalMeters: 10_000
            )
            request.resultTypes = .pointOfInterest
            request.pointOfInterestFilter = MKPointOfInterestFilter(including: [.restaurant])

            let search = MKLocalSearch(request: request)
            let response = try await search.start()

            return response.mapItems.enumerated().compactMap { index, item in
                guard let name = item.name, !name.isEmpty else { return nil }

                let coordinate = item.location.coordinate
                return RestaurantModels.MapKitRestaurantResult(
                    name: name,
                    phoneNumber: item.phoneNumber,
                    websiteURL: item.url,
                    address: MapKitAddressFormatter.displayAddress(
                        item.address?.shortAddress ?? item.address?.fullAddress
                    ),
                    latitude: coordinate.latitude,
                    longitude: coordinate.longitude,
                    popularityRank: index + 1,
                    mapItemIdentifier: item.identifier?.rawValue
                )
            }
        } catch {
            return []
        }
    }

    static func coordinateKey(latitude: Double, longitude: Double) -> String {
        "\(Int((latitude * 10_000).rounded()))_\(Int((longitude * 10_000).rounded()))"
    }

    static func mergeResults(
        mapKit: [RestaurantModels.MapKitRestaurantResult],
        overpass: [RestaurantModels.OverpassRestaurant],
        cityName: String
    ) -> [CityRestaurantCandidate] {
        let normalizedCityName = cityName.folding(
            options: [.caseInsensitive, .diacriticInsensitive],
            locale: .current
        )

        return mapKit.compactMap { mapItem in
            let normalizedName = mapItem.name.folding(
                options: [.caseInsensitive, .diacriticInsensitive],
                locale: .current
            )

            guard normalizedName != normalizedCityName,
                  !self.excludedKeywords.contains(where: {
                      normalizedName.localizedStandardContains($0)
                  })
            else {
                return nil
            }

            let overpassMatch = self.findOverpassMatch(for: mapItem, in: overpass)

            let coordinateKey = self.coordinateKey(
                latitude: mapItem.latitude,
                longitude: mapItem.longitude
            )

            let metadataScore = overpassMatch.map { self.metadataScore(for: $0) } ?? 0

            let cuisine = overpassMatch?.cuisine
                ?? CuisineInferrer.infer(from: mapItem.name)

            return CityRestaurantCandidate(
                id: "mapkit-\(coordinateKey)",
                name: mapItem.name,
                cuisine: cuisine,
                address: mapItem.address ?? overpassMatch?.address,
                hours: overpassMatch?.openingHours,
                phoneNumber: mapItem.phoneNumber ?? overpassMatch?.phoneNumber,
                websiteURL: mapItem.websiteURL ?? overpassMatch?.website,
                sourceURL: self.sourceURL(
                    elementType: overpassMatch?.elementType,
                    elementIdentifier: overpassMatch?.elementIdentifier
                ),
                sourceName: overpassMatch != nil ? "Apple Maps + OpenStreetMap" : "Apple Maps",
                latitude: mapItem.latitude,
                longitude: mapItem.longitude,
                wheelchairAccessibility: overpassMatch?.wheelchairAccessibility ?? .unknown,
                offersVegetarianOptions: overpassMatch?.offersVegetarianOptions ?? false,
                offersVeganOptions: overpassMatch?.offersVeganOptions ?? false,
                hasOutdoorSeating: overpassMatch?.hasOutdoorSeating ?? false,
                acceptsReservations: overpassMatch?.acceptsReservations ?? false,
                isNotable: overpassMatch?.isNotable ?? false,
                brand: overpassMatch?.brand,
                popularityRank: mapItem.popularityRank,
                crossQueryAppearanceCount: mapItem.crossQueryAppearanceCount,
                foodQueryAppearanceCount: mapItem.foodQueryAppearanceCount,
                metadataRichnessScore: metadataScore,
                hasOSMStarRating: overpassMatch?.hasStarRating ?? false,
                isOrganic: overpassMatch?.isOrganic ?? false,
                dietaryVarietyCount: Self.dietaryVarietyCount(for: overpassMatch),
                hasBrandWikidata: overpassMatch?.hasBrandWikidata ?? false,
                hasOperator: overpassMatch?.hasOperator ?? false,
                mapItemIdentifier: mapItem.mapItemIdentifier
            )
        }
    }

    static func findOverpassMatch(
        for mapKitResult: RestaurantModels.MapKitRestaurantResult,
        in overpassResults: [RestaurantModels.OverpassRestaurant]
    ) -> RestaurantModels.OverpassRestaurant? {
        let normalizedMapName = mapKitResult.name.folding(
            options: [.caseInsensitive, .diacriticInsensitive],
            locale: .current
        )

        return overpassResults.first { overpassItem in
            let normalizedOverpassName = overpassItem.name.folding(
                options: [.caseInsensitive, .diacriticInsensitive],
                locale: .current
            )

            let nameMatches = normalizedMapName == normalizedOverpassName
                || normalizedMapName.localizedStandardContains(normalizedOverpassName)
                || normalizedOverpassName.localizedStandardContains(normalizedMapName)

            guard nameMatches else { return false }

            if let overpassLat = overpassItem.latitude,
               let overpassLon = overpassItem.longitude
            {
                let distance = CLLocation(
                    latitude: mapKitResult.latitude,
                    longitude: mapKitResult.longitude
                ).distance(from: CLLocation(latitude: overpassLat, longitude: overpassLon))
                return distance < 200
            }

            return true
        }
    }
}
