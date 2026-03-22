import CoreLocation
import Foundation

// MARK: - CityRestaurantCandidate

struct CityRestaurantCandidate: Sendable, Hashable {
    let id: String
    let name: String
    let cuisine: String?
    let address: String?
    let hours: String?
    let phoneNumber: String?
    let websiteURL: URL?
    let sourceURL: URL?
    let sourceName: String
    let latitude: Double?
    let longitude: Double?
    let wheelchairAccessibility: CityRestaurant.AccessibilityLevel
    let offersVegetarianOptions: Bool
    let offersVeganOptions: Bool
    let hasOutdoorSeating: Bool
    let acceptsReservations: Bool
    let isNotable: Bool
    let brand: String?
    let popularityRank: Int?

    // Pillar 1: How many independent MapKit queries returned this restaurant
    var crossQueryAppearanceCount: Int = 1

    // Pillar 2: Wikidata award/recognition data
    var wikidataAwardCount: Int = 0
    var isMichelinRecognized: Bool = false

    // Pillar 3: OSM metadata richness (higher = more community-curated data)
    var metadataRichnessScore: Int = 0
}

// MARK: - CityRestaurantRanking

enum CityRestaurantRanking {
    struct ScoredCandidate: Sendable {
        let candidate: CityRestaurantCandidate
        let baseScore: Int
        let topSignals: [Signal]
        let distanceFromCenter: CLLocationDistance?
        let primaryCuisineKey: String?
    }

    enum Signal: Sendable {
        case popularChoice
        case crossQueryPopular
        case awardWinning
        case notable
        case metadataRich
        case establishedPresence
        case cuisine
        case centralLocation

        var points: Int {
            switch self {
            case .popularChoice:
                15
            case .crossQueryPopular:
                12
            case .awardWinning:
                14
            case .notable:
                10
            case .metadataRich:
                5
            case .establishedPresence:
                4
            case .cuisine:
                2
            case .centralLocation:
                1
            }
        }

        var badgeText: String {
            switch self {
            case .popularChoice:
                "Popular"
            case .crossQueryPopular:
                "Highly Rated"
            case .awardWinning:
                "Award-Winning"
            case .notable:
                "Notable"
            case .metadataRich:
                "Well-Known"
            case .establishedPresence:
                "Established"
            case .cuisine:
                "Cuisine"
            case .centralLocation:
                "Central"
            }
        }

        var summaryFragment: String {
            switch self {
            case .popularChoice:
                "high popularity among visitors and locals"
            case .crossQueryPopular:
                "consistently appearing across multiple recommendation categories"
            case .awardWinning:
                "recognized culinary awards and distinctions"
            case .notable:
                "strong recognition and acclaim"
            case .metadataRich:
                "extensive community-contributed information"
            case .establishedPresence:
                "an established dining presence"
            case .cuisine:
                "a well-defined culinary identity"
            case .centralLocation:
                "a convenient central location"
            }
        }
    }

    static func topRestaurants(
        from candidates: [CityRestaurantCandidate],
        for city: CityModel,
        limit: Int = 6
    ) -> [CityRestaurant] {
        let scored = candidates
            .map { self.score($0, cityCoordinate: city.coordinate) }
            .sorted { lhs, rhs in
                if lhs.baseScore != rhs.baseScore {
                    return lhs.baseScore > rhs.baseScore
                }

                let lhsRank = lhs.candidate.popularityRank ?? .max
                let rhsRank = rhs.candidate.popularityRank ?? .max
                if lhsRank != rhsRank {
                    return lhsRank < rhsRank
                }

                return (lhs.distanceFromCenter ?? .greatestFiniteMagnitude)
                    < (rhs.distanceFromCenter ?? .greatestFiniteMagnitude)
            }

        return self.selectDiverseRestaurants(from: scored, for: city, limit: limit)
    }

    static func score(
        _ candidate: CityRestaurantCandidate,
        cityCoordinate: CLLocationCoordinate2D
    ) -> ScoredCandidate {
        var signals: [Signal] = []
        var score = 0

        score += self.scorePopularity(candidate, signals: &signals)
        score += self.scoreCrossQuery(candidate, signals: &signals)
        score += self.scoreAwards(candidate, signals: &signals)
        score += self.scoreMetadata(candidate, signals: &signals)
        score += self.scorePresence(candidate, signals: &signals)

        let distanceFromCenter = self.distance(
            from: cityCoordinate,
            latitude: candidate.latitude,
            longitude: candidate.longitude
        )
        score += self.scoreLocation(distanceFromCenter, signals: &signals)
        score += self.scorePenalties(candidate)

        return ScoredCandidate(
            candidate: candidate,
            baseScore: score,
            topSignals: signals.sorted { lhs, rhs in
                if lhs.points != rhs.points { return lhs.points > rhs.points }
                return lhs.badgeText < rhs.badgeText
            },
            distanceFromCenter: distanceFromCenter,
            primaryCuisineKey: self.primaryCuisineKey(for: candidate.cuisine)
        )
    }

    // MARK: - Scoring Helpers

    private static func scorePopularity(
        _ candidate: CityRestaurantCandidate,
        signals: inout [Signal]
    ) -> Int {
        guard let rank = candidate.popularityRank else { return 0 }
        switch rank {
        case 1 ... 5:
            signals.append(.popularChoice)
            return 15
        case 6 ... 10:
            signals.append(.popularChoice)
            return 10
        case 11 ... 20:
            return 6
        default:
            return 3
        }
    }

    private static func scoreCrossQuery(
        _ candidate: CityRestaurantCandidate,
        signals: inout [Signal]
    ) -> Int {
        if candidate.crossQueryAppearanceCount >= 3 {
            signals.append(.crossQueryPopular)
            return Signal.crossQueryPopular.points
        } else if candidate.crossQueryAppearanceCount == 2 {
            return 6
        }
        return 0
    }

    private static func scoreAwards(
        _ candidate: CityRestaurantCandidate,
        signals: inout [Signal]
    ) -> Int {
        if candidate.isMichelinRecognized {
            signals.append(.awardWinning)
            return Signal.awardWinning.points
        } else if candidate.wikidataAwardCount > 0 {
            signals.append(.awardWinning)
            return 8
        }

        if candidate.isNotable {
            signals.append(.notable)
            return Signal.notable.points
        }

        return 0
    }

    private static func scoreMetadata(
        _ candidate: CityRestaurantCandidate,
        signals: inout [Signal]
    ) -> Int {
        if candidate.metadataRichnessScore >= 20 {
            signals.append(.metadataRich)
            return Signal.metadataRich.points
        } else if candidate.metadataRichnessScore >= 12 {
            return 3
        } else if candidate.metadataRichnessScore >= 6 {
            return 1
        }
        return 0
    }

    private static func scorePresence(
        _ candidate: CityRestaurantCandidate,
        signals: inout [Signal]
    ) -> Int {
        var score = 0

        if candidate.websiteURL != nil {
            signals.append(.establishedPresence)
            score += Signal.establishedPresence.points
        }

        if candidate.cuisine?.isEmpty == false {
            signals.append(.cuisine)
            score += Signal.cuisine.points
        }

        return score
    }

    private static func scoreLocation(
        _ distanceFromCenter: CLLocationDistance?,
        signals: inout [Signal]
    ) -> Int {
        guard let distanceFromCenter else { return 0 }

        if distanceFromCenter < 1_500 {
            signals.append(.centralLocation)
            return 3
        } else if distanceFromCenter < 4_000 {
            signals.append(.centralLocation)
            return 2
        } else if distanceFromCenter < 8_000 {
            return 1
        }
        return 0
    }

    private static func scorePenalties(_ candidate: CityRestaurantCandidate) -> Int {
        var penalty = 0
        if candidate.brand?.isEmpty == false { penalty -= 4 }
        if self.isGenericName(candidate.name) { penalty -= 3 }
        return penalty
    }

    private static func selectDiverseRestaurants(
        from scored: [ScoredCandidate],
        for city: CityModel,
        limit: Int
    ) -> [CityRestaurant] {
        var remaining = scored
        var selected: [ScoredCandidate] = []
        var seenCuisineKeys: Set<String> = []

        while selected.count < limit, !remaining.isEmpty {
            let bestIndex = remaining.indices.max { lhs, rhs in
                self.selectionScore(
                    for: remaining[lhs],
                    seenCuisineKeys: seenCuisineKeys
                ) < self.selectionScore(
                    for: remaining[rhs],
                    seenCuisineKeys: seenCuisineKeys
                )
            }

            guard let bestIndex else { break }
            let bestCandidate = remaining.remove(at: bestIndex)
            selected.append(bestCandidate)

            if let cuisineKey = bestCandidate.primaryCuisineKey {
                seenCuisineKeys.insert(cuisineKey)
            }
        }

        return selected.map { self.mapToRestaurant($0, city: city) }
    }

    private static func selectionScore(
        for candidate: ScoredCandidate,
        seenCuisineKeys: Set<String>
    ) -> Int {
        var adjustedScore = candidate.baseScore

        if let primaryCuisineKey = candidate.primaryCuisineKey {
            adjustedScore += seenCuisineKeys.contains(primaryCuisineKey) ? -2 : 3
        }

        return adjustedScore
    }

    private static func mapToRestaurant(
        _ scoredCandidate: ScoredCandidate,
        city: CityModel
    ) -> CityRestaurant {
        let highlights = Array(scoredCandidate.topSignals.prefix(3)).map(\.badgeText)

        return CityRestaurant(
            id: scoredCandidate.candidate.id,
            name: scoredCandidate.candidate.name,
            cuisine: scoredCandidate.candidate.cuisine,
            summary: self.summary(
                for: scoredCandidate.candidate,
                city: city,
                signals: Array(scoredCandidate.topSignals.prefix(3))
            ),
            address: scoredCandidate.candidate.address,
            hours: scoredCandidate.candidate.hours,
            phoneNumber: scoredCandidate.candidate.phoneNumber,
            websiteURL: scoredCandidate.candidate.websiteURL,
            sourceURL: scoredCandidate.candidate.sourceURL,
            sourceName: scoredCandidate.candidate.sourceName,
            latitude: scoredCandidate.candidate.latitude,
            longitude: scoredCandidate.candidate.longitude,
            wheelchairAccessibility: scoredCandidate.candidate.wheelchairAccessibility,
            offersVegetarianOptions: scoredCandidate.candidate.offersVegetarianOptions,
            offersVeganOptions: scoredCandidate.candidate.offersVeganOptions,
            hasOutdoorSeating: scoredCandidate.candidate.hasOutdoorSeating,
            acceptsReservations: scoredCandidate.candidate.acceptsReservations,
            rankingScore: scoredCandidate.baseScore,
            rankingHighlights: highlights
        )
    }

    private static func summary(
        for candidate: CityRestaurantCandidate,
        city: CityModel,
        signals: [Signal]
    ) -> String {
        let cuisineLine = if let cuisine = candidate.cuisine {
            "\(candidate.name) is a popular \(cuisine.lowercased()) restaurant in \(city.name)."
        } else {
            "\(candidate.name) is a popular restaurant in \(city.name)."
        }

        let reasonFragments = signals.map(\.summaryFragment)
        let recommendationLine = if reasonFragments.isEmpty {
            "It stands out for its strong local presence."
        } else {
            "It stands out for \(self.joinedList(reasonFragments))."
        }

        return "\(cuisineLine) \(recommendationLine)"
    }

    private static func primaryCuisineKey(for cuisine: String?) -> String? {
        guard let cuisine else { return nil }

        let tokens = cuisine
            .components(separatedBy: "\u{2022}")
            .map { token in
                token
                    .trimmingCharacters(in: .whitespacesAndNewlines)
                    .folding(options: [.caseInsensitive, .diacriticInsensitive], locale: .current)
                    .lowercased()
            }
            .filter { !$0.isEmpty }

        return tokens.first
    }

    private static func distance(
        from coordinate: CLLocationCoordinate2D,
        latitude: Double?,
        longitude: Double?
    ) -> CLLocationDistance? {
        guard let latitude, let longitude else { return nil }

        let cityLocation = CLLocation(
            latitude: coordinate.latitude,
            longitude: coordinate.longitude
        )
        let restaurantLocation = CLLocation(latitude: latitude, longitude: longitude)
        return cityLocation.distance(from: restaurantLocation)
    }

    private static func isGenericName(_ name: String) -> Bool {
        let normalizedName = name
            .folding(options: [.caseInsensitive, .diacriticInsensitive], locale: .current)
            .lowercased()
            .trimmingCharacters(in: .whitespacesAndNewlines)

        return self.genericNames.contains(normalizedName)
    }

    private static func joinedList(_ values: [String]) -> String {
        ListFormatter.localizedString(byJoining: values)
    }

    private static let genericNames: Set<String> = [
        "restaurant",
        "restaurante",
        "restaurant & bar",
        "dining room",
        "hotel restaurant"
    ]
}
