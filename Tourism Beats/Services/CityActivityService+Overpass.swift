import Foundation
import OSLog

// MARK: - Overpass API (OpenStreetMap)

extension CityActivityService {
    func overpassPOIs(
        latitude: Double,
        longitude: Double,
        cityName: String
    ) async throws -> [Models.OverpassPOI] {
        let radius = 12_000
        let query = Self.overpassQuery(latitude: latitude, longitude: longitude, radius: radius)
        let data = try await self.overpassClient.data(for: query)
        let response = try self.decoder.decode(Models.OverpassResponse.self, from: data)

        return Self.processOverpassElements(response.elements, cityName: cityName)
    }

    static func overpassQuery(latitude: Double, longitude: Double, radius: Int) -> String {
        """
        [out:json][timeout:20];
        (
          nwr["tourism"~"attraction|museum|gallery|artwork|viewpoint|zoo|aquarium|theme_park"]\
        (around:\(radius),\(latitude),\(longitude));
          nwr["historic"~"monument|memorial|castle|ruins|fort|archaeological_site|palace|city_gate"]\
        (around:\(radius),\(latitude),\(longitude));
          nwr["leisure"~"park|garden|nature_reserve|stadium"]\
        (around:\(radius),\(latitude),\(longitude))["name"];
          nwr["amenity"~"theatre|place_of_worship"]\
        (around:\(radius),\(latitude),\(longitude))["name"]["wikidata"];
        );
        out center 60;
        """
    }

    static func processOverpassElements(
        _ elements: [Models.OverpassElement],
        cityName: String
    ) -> [Models.OverpassPOI] {
        let cityNormalized = cityName.folding(
            options: [.caseInsensitive, .diacriticInsensitive],
            locale: .current
        )

        var seen = Set<String>()
        var pois: [Models.OverpassPOI] = []

        for element in elements {
            guard let name = element.tags?.name, !name.isEmpty else { continue }

            let nameNormalized = name.folding(
                options: [.caseInsensitive, .diacriticInsensitive],
                locale: .current
            )

            guard nameNormalized != cityNormalized,
                  !seen.contains(nameNormalized),
                  !self.excludedKeywords.contains(where: { nameNormalized.localizedStandardContains($0) })
            else { continue }

            seen.insert(nameNormalized)

            pois.append(Models.OverpassPOI(
                name: name,
                latitude: element.lat ?? element.center?.lat,
                longitude: element.lon ?? element.center?.lon,
                tourism: element.tags?.tourism,
                historic: element.tags?.historic,
                leisure: element.tags?.leisure,
                amenity: element.tags?.amenity,
                wikipedia: element.tags?.wikipedia,
                wikidata: element.tags?.wikidata,
                website: element.tags?.website,
                openingHours: element.tags?.openingHours,
                fee: element.tags?.fee,
                address: self.buildAddress(from: element.tags)
            ))
        }

        return pois.sorted { self.notabilityScore($0) > self.notabilityScore($1) }
    }

    static func notabilityScore(_ poi: Models.OverpassPOI) -> Int {
        var score = 0
        if poi.wikipedia != nil { score += 10 }
        if poi.wikidata != nil { score += 5 }
        if poi.website != nil { score += 2 }
        if poi.tourism == "museum" { score += 8 }
        if poi.tourism == "attraction" { score += 7 }
        if poi.historic == "castle" || poi.historic == "palace" { score += 7 }
        if poi.tourism == "gallery" { score += 6 }
        if poi.tourism == "zoo" || poi.tourism == "aquarium" { score += 6 }
        if poi.historic == "monument" || poi.historic == "memorial" { score += 5 }
        if poi.tourism == "viewpoint" { score += 4 }
        if poi.amenity == "theatre" { score += 4 }
        if poi.leisure == "park" || poi.leisure == "garden" { score += 3 }
        if poi.leisure == "stadium" { score += 3 }
        if poi.amenity == "place_of_worship" { score += 3 }
        return score
    }

    static func buildAddress(from tags: Models.OverpassTags?) -> String? {
        guard let tags else { return nil }
        var parts: [String] = []
        if let street = tags.addrStreet {
            if let number = tags.addrHousenumber {
                parts.append("\(number) \(street)")
            } else {
                parts.append(street)
            }
        }
        if let city = tags.addrCity { parts.append(city) }
        return parts.isEmpty ? nil : parts.joined(separator: ", ")
    }

    static let excludedKeywords = [
        "district", "neighborhood", "neighbourhood", "county",
        "school", "university", "college", "hospital",
        "cemetery", "freeway", "highway", "route ",
        "interchange", "census", "election", "demographic",
        "parking", "toilet", "recycling"
    ]
}

// MARK: - Wikipedia Enrichment

extension CityActivityService {
    func enrichWithWikipedia(pois: [Models.OverpassPOI]) async -> [CityActivity] {
        let wikiTitles: [(Int, String)] = pois.enumerated().compactMap { index, poi in
            if let wiki = poi.wikipedia, wiki.hasPrefix("en:") {
                return (index, String(wiki.dropFirst(3)))
            }
            return (index, poi.name)
        }

        let titleStrings = wikiTitles.map(\.1)
        var allPages: [String: Models.WikiPageDetail] = [:]

        for batch in stride(from: 0, to: titleStrings.count, by: 20) {
            let batchTitles = Array(titleStrings[batch ..< min(batch + 20, titleStrings.count)])
            if let pages = try? await self.wikiPageDetails(for: batchTitles) {
                for page in pages {
                    allPages[page.title.lowercased()] = page
                }
            }
        }

        return pois.enumerated().map { index, poi in
            let searchTitle = wikiTitles.first { $0.0 == index }?.1 ?? poi.name
            let page = allPages[searchTitle.lowercased()] ?? allPages[poi.name.lowercased()]
            return Self.mapPOIToActivity(poi: poi, page: page)
        }
    }

    static func mapPOIToActivity(
        poi: Models.OverpassPOI,
        page: Models.WikiPageDetail?
    ) -> CityActivity {
        let result = Models.categoryFromPOI(poi: poi)

        let imageURL: URL? = if let source = page?.original?.source {
            URL(string: source)
        } else if let source = page?.thumbnail?.source {
            URL(string: source)
        } else {
            nil
        }

        let summary = if let extract = page?.extract, !extract.isEmpty {
            Self.cleanExtract(extract)
        } else {
            "A notable \(result.category.lowercased()) worth visiting."
        }

        let encodedName = (page?.title ?? poi.name)
            .replacingOccurrences(of: " ", with: "_")
            .addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? poi.name

        let sourceURL: URL? = if page != nil {
            URL(string: "https://en.wikipedia.org/wiki/\(encodedName)", encodingInvalidCharacters: true)
        } else {
            nil
        }

        let officialURL: URL? = if let website = poi.website {
            URL(string: website, encodingInvalidCharacters: true)
        } else {
            nil
        }

        return CityActivity(
            id: "osm-\(page?.pageid ?? poi.name.hashValue)",
            name: poi.name,
            summary: summary,
            category: result.category,
            kind: result.kind,
            imageURL: imageURL,
            officialURL: officialURL,
            sourceURL: sourceURL,
            sourceName: "OpenStreetMap",
            hours: poi.openingHours,
            price: poi.fee == "yes" ? "Paid admission" : (poi.fee == "no" ? "Free" : nil),
            address: poi.address,
            directions: nil,
            timingTip: nil,
            latitude: poi.latitude,
            longitude: poi.longitude,
            wikidataIdentifier: poi.wikidata ?? page?.pageprops?.wikidataItem,
            sourcePageTitle: page?.title,
            sourceAnchor: nil
        )
    }
}
