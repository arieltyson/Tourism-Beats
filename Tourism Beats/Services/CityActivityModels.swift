import Foundation

// MARK: - CityActivityService Response Models

/// Internal response models used by ``CityActivityService`` for decoding
/// Overpass, Wikipedia, and Wikidata API responses.
enum CityActivityAPIModels {
    // MARK: Overpass

    struct OverpassResponse: Decodable {
        let elements: [OverpassElement]

        init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            self.elements = (try? container.decode([OverpassElement].self, forKey: .elements)) ?? []
        }

        private enum CodingKeys: String, CodingKey {
            case elements
        }
    }

    struct OverpassElement: Decodable {
        let type: String?
        let id: Int?
        let lat: Double?
        let lon: Double?
        let center: OverpassCenter?
        let tags: OverpassTags?
    }

    struct OverpassCenter: Decodable {
        let lat: Double
        let lon: Double
    }

    struct OverpassTags: Decodable {
        let name: String?
        let tourism: String?
        let historic: String?
        let leisure: String?
        let amenity: String?
        let wikipedia: String?
        let wikidata: String?
        let website: String?
        let openingHours: String?
        let fee: String?
        let addrStreet: String?
        let addrHousenumber: String?
        let addrCity: String?

        private enum CodingKeys: String, CodingKey {
            case name
            case tourism
            case historic
            case leisure
            case amenity
            case wikipedia
            case wikidata
            case website
            case openingHours = "opening_hours"
            case fee
            case addrStreet = "addr:street"
            case addrHousenumber = "addr:housenumber"
            case addrCity = "addr:city"
        }
    }

    struct OverpassPOI {
        let name: String
        let latitude: Double?
        let longitude: Double?
        let tourism: String?
        let historic: String?
        let leisure: String?
        let amenity: String?
        let wikipedia: String?
        let wikidata: String?
        let website: String?
        let openingHours: String?
        let fee: String?
        let address: String?
    }

    // MARK: Wikipedia

    struct GeoSearchResponse: Decodable {
        let query: GeoSearchQuery?
    }

    struct GeoSearchQuery: Decodable {
        let geosearch: [GeoSearchResult]?
    }

    struct GeoSearchResult: Decodable, Sendable {
        let pageid: Int
        let title: String
        let lat: Double
        let lon: Double
        let dist: Double
    }

    struct WikiPageQueryResponse: Decodable {
        let query: WikiPageQueryData?
    }

    struct WikiPageQueryData: Decodable {
        let pages: [WikiPageDetail]?
    }

    struct WikiPageDetail: Decodable {
        let pageid: Int
        let title: String
        let extract: String?
        let thumbnail: PageImage?
        let original: PageImage?
        let coordinates: [PageCoordinate]?
        let pageprops: PageProps?
    }

    struct PageImage: Decodable {
        let source: String
        let width: Int?
        let height: Int?
    }

    struct PageCoordinate: Decodable {
        let lat: Double
        let lon: Double
    }

    struct PageProps: Decodable {
        let wikibase_item: String?

        var wikidataItem: String? { self.wikibase_item }

        private enum CodingKeys: String, CodingKey {
            case wikibase_item
        }
    }

    // MARK: Wikivoyage

    struct WikimediaParseResponse: Decodable {
        let parse: WikimediaParsePayload?
        let error: WikimediaErrorPayload?
    }

    struct WikimediaParsePayload: Decodable {
        let title: String
        let wikitext: String?
        let tocdata: WikimediaTOCData?
    }

    struct WikimediaTOCData: Decodable {
        let sections: [WikimediaTOCSection]
    }

    struct WikimediaTOCSection: Decodable, Sendable {
        let line: String
        let index: String
        let tocLevel: Int
        let anchor: String
    }

    struct WikimediaErrorPayload: Decodable {
        let code: String
        let info: String
    }

    struct WikimediaPageviewsResponse: Decodable {
        let items: [WikimediaPageviewItem]?
    }

    struct WikimediaPageviewItem: Decodable {
        let views: Int?
    }

    // MARK: Wikidata

    struct WikidataEntitiesResponse: Decodable {
        let entities: [String: WikidataEntity]

        init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            self.entities = (try? container.decode(
                [String: WikidataEntity].self,
                forKey: .entities
            )) ?? [:]
        }

        private enum CodingKeys: String, CodingKey {
            case entities
        }
    }

    struct WikidataEntity: Decodable {
        let claims: [String: [WikidataClaim]]?
    }

    struct WikidataClaim: Decodable {
        let mainsnak: WikidataMainsnak
    }

    struct WikidataMainsnak: Decodable {
        let datavalue: WikidataDatavalue?
    }

    struct WikidataDatavalue: Decodable {
        let value: WikidataValue
    }

    struct WikidataValue: Decodable {
        let stringValue: String?

        init(from decoder: Decoder) throws {
            let container = try decoder.singleValueContainer()
            self.stringValue = try? container.decode(String.self)
        }
    }

    // MARK: Internal

    struct CachedPayload: Codable, Sendable {
        let fetchedAt: Date
        let activities: [CityActivity]

        func isValid(lifetime: TimeInterval) -> Bool {
            self.fetchedAt.addingTimeInterval(lifetime) > .now
        }
    }

    enum ServiceError: Error {
        case invalidResponse
        case invalidRequest
        case httpStatus(Int)
    }

    struct MapKitActivityResult: Sendable {
        let name: String
        let websiteURL: URL?
        let address: String?
        let latitude: Double
        let longitude: Double
        let popularityRank: Int
        var crossQueryAppearanceCount: Int = 1
        var reviewQueryAppearanceCount: Int = 0
    }

    // MARK: Category Classification

    struct CategoryResult {
        let category: String
        let kind: CityActivity.Kind
    }

    static func categoryFromPOI(poi: OverpassPOI) -> CategoryResult {
        if let result = tourismCategory(poi.tourism) { return result }
        if let result = historicCategory(poi.historic) { return result }
        if let result = leisureCategory(poi.leisure) { return result }
        if poi.amenity == "theatre" { return CategoryResult(category: "Entertainment", kind: .do) }
        if poi.amenity == "place_of_worship" { return CategoryResult(category: "Architecture", kind: .see) }
        return CategoryResult(category: "Attraction", kind: .see)
    }

    private static func tourismCategory(_ tourism: String?) -> CategoryResult? {
        guard let tourism else { return nil }
        switch tourism {
        case "museum": return CategoryResult(category: "Museum", kind: .see)
        case "gallery": return CategoryResult(category: "Gallery", kind: .see)
        case "artwork": return CategoryResult(category: "Art", kind: .see)
        case "viewpoint": return CategoryResult(category: "Viewpoint", kind: .see)
        case "zoo": return CategoryResult(category: "Zoo", kind: .do)
        case "aquarium": return CategoryResult(category: "Aquarium", kind: .do)
        case "theme_park": return CategoryResult(category: "Theme Park", kind: .do)
        case "attraction": return CategoryResult(category: "Attraction", kind: .see)
        default: return nil
        }
    }

    private static func historicCategory(_ historic: String?) -> CategoryResult? {
        guard let historic else { return nil }
        switch historic {
        case "castle", "palace": return CategoryResult(category: "Heritage", kind: .see)
        case "memorial", "monument": return CategoryResult(category: "Landmark", kind: .see)
        case "city_gate", "fort": return CategoryResult(category: "Heritage", kind: .see)
        case "archaeological_site", "ruins": return CategoryResult(category: "Heritage", kind: .see)
        default: return CategoryResult(category: "Heritage", kind: .see)
        }
    }

    private static func leisureCategory(_ leisure: String?) -> CategoryResult? {
        guard let leisure else { return nil }
        switch leisure {
        case "garden", "nature_reserve", "park": return CategoryResult(category: "Nature", kind: .do)
        case "stadium": return CategoryResult(category: "Sports", kind: .do)
        default: return nil
        }
    }

    static func categoryFromText(title: String, extract: String) -> CategoryResult {
        let text = "\(title) \(extract)".lowercased()

        for rule in self.categoryRules where rule.keywords.contains(where: { text.localizedStandardContains($0) }) {
            return CategoryResult(category: rule.category, kind: rule.kind)
        }

        return CategoryResult(category: "Attraction", kind: .see)
    }

    private struct CategoryRule {
        let keywords: [String]
        let category: String
        let kind: CityActivity.Kind
    }

    private static let categoryRules: [CategoryRule] = [
        CategoryRule(keywords: ["museum", "gallery", "exhibit"], category: "Museum", kind: .see),
        CategoryRule(keywords: ["park", "garden", "botanical", "forest", "trail"], category: "Nature", kind: .do),
        CategoryRule(keywords: ["bridge", "tower", "monument", "statue", "memorial"], category: "Landmark", kind: .see),
        CategoryRule(
            keywords: ["church", "cathedral", "temple", "mosque", "basilica", "chapel"],
            category: "Architecture",
            kind: .see
        ),
        CategoryRule(keywords: ["beach", "island", "bay", "lake", "waterfall", "reef"], category: "Nature", kind: .see),
        CategoryRule(
            keywords: ["theater", "theatre", "opera", "concert", "performing"],
            category: "Entertainment",
            kind: .do
        ),
        CategoryRule(keywords: ["stadium", "arena", "ballpark"], category: "Sports", kind: .do),
        CategoryRule(
            keywords: ["market", "square", "plaza", "bazaar", "wharf", "pier"],
            category: "Culture",
            kind: .do
        ),
        CategoryRule(keywords: ["palace", "castle", "fort", "fortress", "citadel"], category: "Heritage", kind: .see),
        CategoryRule(keywords: ["zoo", "aquarium", "amusement", "theme park"], category: "Family", kind: .do),
        CategoryRule(
            keywords: ["library", "university", "observatory", "planetarium"],
            category: "Education",
            kind: .see
        ),
        CategoryRule(keywords: ["harbor", "harbour", "lighthouse", "dam"], category: "Landmark", kind: .see)
    ]
}
