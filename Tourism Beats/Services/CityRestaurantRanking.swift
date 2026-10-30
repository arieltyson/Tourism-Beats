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

    // Food quality: How many food-quality-specific MapKit queries returned this
    var foodQueryAppearanceCount: Int = 0

    /// Where the place sits across every Apple Maps search, fused to 0...1.
    /// The strongest free evidence of high ratings from many reviewers; see
    /// `RestaurantRankFusion`.
    var appleMapsConsensus: Double = 0

    // Pillar 2: Wikidata award/recognition data
    var wikidataAwardCount: Int = 0
    var isMichelinRecognized: Bool = false

    /// Recommended in the city's Wikivoyage guide by its editors.
    var isGuideRecommended: Bool = false

    // Pillar 3: OSM metadata richness (higher = more community-curated data)
    var metadataRichnessScore: Int = 0

    // OSM food quality indicators
    var hasOSMStarRating: Bool = false
    var isOrganic: Bool = false
    var dietaryVarietyCount: Int = 0

    // Chain/generic detection signals
    var hasBrandWikidata: Bool = false
    var hasOperator: Bool = false
    var duplicateLocationCount: Int = 0

    /// Apple Maps' identifier for the place, when it came from Apple Maps.
    var mapItemIdentifier: String?
}

// MARK: - CityRestaurantRanking

enum CityRestaurantRanking {
    struct ScoredCandidate: Sendable {
        let candidate: CityRestaurantCandidate
        let baseScore: Double
        let topSignals: [Signal]
        let distanceFromCenter: CLLocationDistance?
        let primaryCuisineKey: String?
    }

    enum Signal: Sendable {
        case popularChoice
        case crossQueryPopular
        case foodQualityEndorsed
        case awardWinning
        case guideRecommended
        case notable
        case metadataRich
        case establishedPresence
        case cuisine
        case centralLocation

        var points: Int {
            switch self {
            case .popularChoice:
                15
            case .foodQualityEndorsed:
                13
            case .crossQueryPopular:
                12
            case .awardWinning:
                14
            case .guideRecommended:
                12
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
            case .foodQualityEndorsed:
                "Great Food"
            case .awardWinning:
                "Award-Winning"
            case .guideRecommended:
                "Guide Pick"
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
            case .foodQualityEndorsed:
                "strong food quality reputation across review categories"
            case .awardWinning:
                "recognized culinary awards and distinctions"
            case .guideRecommended:
                "a recommendation from travel guide editors"
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

    /// Points each kind of evidence is worth. Apple Maps' consensus (0...1)
    /// is scaled to 100, so a restaurant at the top of every search outranks
    /// any amount of expert recognition alone, while recognition still lifts
    /// a well-reviewed place above an equally reviewed one.
    enum Weight {
        static let appleMapsConsensus: Double = 100
        static let michelin: Double = 40
        static let otherAward: Double = 20
        static let notable: Double = 10
        /// Editors' picks are curated but less selective than awards.
        static let guideRecommended: Double = 25
        /// Each sign of a well-documented place; enough only to break ties.
        static let tiebreaker: Double = 1
        /// Chain penalties were sized for the old 60-point scale.
        static let chainPenaltyScale: Double = 2
        /// Nudges toward a varied selection without overriding the evidence.
        static let newCuisine: Double = 4
        static let repeatedCuisine: Double = 3
    }

    enum Threshold {
        static let popularRank = 10
        static let highlyRatedConsensus = 0.4
        static let crossQueryAppearances = 3
        static let foodQueryAppearances = 2
        static let richMetadata = 20
        static let centralDistance: CLLocationDistance = 1_500
        static let nearbyDistance: CLLocationDistance = 4_000
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
        let distanceFromCenter = self.distance(
            from: cityCoordinate,
            latitude: candidate.latitude,
            longitude: candidate.longitude
        )
        let signals = self.signals(for: candidate, distanceFromCenter: distanceFromCenter)

        return ScoredCandidate(
            candidate: candidate,
            baseScore: self.evidenceScore(for: candidate, distanceFromCenter: distanceFromCenter),
            topSignals: signals.sorted { lhs, rhs in
                if lhs.points != rhs.points { return lhs.points > rhs.points }
                return lhs.badgeText < rhs.badgeText
            },
            distanceFromCenter: distanceFromCenter,
            primaryCuisineKey: self.primaryCuisineKey(for: candidate.cuisine)
        )
    }

    // MARK: - Evidence Score

    /// How strongly the evidence says a restaurant is excellent.
    ///
    /// Apple Maps' consensus is the backbone, since its ordering reflects
    /// ratings and review volume. Expert recognition adds to it as
    /// independent evidence. What only shows a place is well documented (a
    /// website, a cuisine tag, rich map data, a central address) merely breaks
    /// ties, so it can never lift a mediocre restaurant past a loved one.
    static func evidenceScore(
        for candidate: CityRestaurantCandidate,
        distanceFromCenter: CLLocationDistance?
    ) -> Double {
        var score = Weight.appleMapsConsensus * self.appleMapsConsensus(for: candidate)

        if candidate.isMichelinRecognized {
            score += Weight.michelin
        } else if candidate.wikidataAwardCount > 0 {
            score += Weight.otherAward
        } else if candidate.isNotable {
            score += Weight.notable
        }

        // Independent of awards: a place can be both a Michelin pick and a guide pick.
        if candidate.isGuideRecommended {
            score += Weight.guideRecommended
        }

        score += self.tiebreakers(for: candidate, distanceFromCenter: distanceFromCenter)
        score += Double(self.chainPenalty(for: candidate)) * Weight.chainPenaltyScale

        return score
    }

    /// The fused Apple Maps consensus, or, for a restaurant known only by its
    /// best position, the consensus of that one appearance.
    static func appleMapsConsensus(for candidate: CityRestaurantCandidate) -> Double {
        if candidate.appleMapsConsensus > 0 {
            return candidate.appleMapsConsensus
        }
        return candidate.popularityRank.map(RestaurantRankFusion.consensus(forSinglePosition:)) ?? 0
    }

    private static func tiebreakers(
        for candidate: CityRestaurantCandidate,
        distanceFromCenter: CLLocationDistance?
    ) -> Double {
        var score: Double = 0

        if candidate.websiteURL != nil { score += Weight.tiebreaker }
        if candidate.cuisine?.isEmpty == false { score += Weight.tiebreaker }
        if candidate.hasOSMStarRating { score += Weight.tiebreaker }
        if candidate.metadataRichnessScore >= Threshold.richMetadata { score += Weight.tiebreaker }
        if let distanceFromCenter, distanceFromCenter < Threshold.centralDistance {
            score += Weight.tiebreaker
        }

        return score
    }

    private static func chainPenalty(for candidate: CityRestaurantCandidate) -> Int {
        CityRestaurantChainDetector.confidence(
            name: candidate.name,
            brand: candidate.brand,
            hasBrandWikidata: candidate.hasBrandWikidata,
            hasOperator: candidate.hasOperator,
            duplicateLocationCount: candidate.duplicateLocationCount
        ).penalty
    }

    // MARK: - Highlights

    /// The reasons shown on a restaurant's page. They explain the ranking but
    /// don't drive it.
    private static func signals(
        for candidate: CityRestaurantCandidate,
        distanceFromCenter: CLLocationDistance?
    ) -> [Signal] {
        var signals: [Signal] = []

        if let rank = candidate.popularityRank, rank <= Threshold.popularRank {
            signals.append(.popularChoice)
        }
        if self.appleMapsConsensus(for: candidate) >= Threshold.highlyRatedConsensus
            || candidate.crossQueryAppearanceCount >= Threshold.crossQueryAppearances
        {
            signals.append(.crossQueryPopular)
        }
        if candidate.foodQueryAppearanceCount >= Threshold.foodQueryAppearances {
            signals.append(.foodQualityEndorsed)
        }
        if candidate.isMichelinRecognized || candidate.wikidataAwardCount > 0 {
            signals.append(.awardWinning)
        } else if candidate.isNotable {
            signals.append(.notable)
        }
        if candidate.isGuideRecommended {
            signals.append(.guideRecommended)
        }
        if candidate.metadataRichnessScore >= Threshold.richMetadata {
            signals.append(.metadataRich)
        }
        if candidate.websiteURL != nil {
            signals.append(.establishedPresence)
        }
        if candidate.cuisine?.isEmpty == false {
            signals.append(.cuisine)
        }
        if let distanceFromCenter, distanceFromCenter < Threshold.nearbyDistance {
            signals.append(.centralLocation)
        }

        return signals
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
    ) -> Double {
        guard let primaryCuisineKey = candidate.primaryCuisineKey else {
            return candidate.baseScore
        }

        return candidate.baseScore + (seenCuisineKeys.contains(primaryCuisineKey)
            ? -Weight.repeatedCuisine
            : Weight.newCuisine)
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
            rankingScore: Int(scoredCandidate.baseScore.rounded()),
            rankingHighlights: highlights,
            mapItemIdentifier: scoredCandidate.candidate.mapItemIdentifier
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

    private static func joinedList(_ values: [String]) -> String {
        ListFormatter.localizedString(byJoining: values)
    }
}
