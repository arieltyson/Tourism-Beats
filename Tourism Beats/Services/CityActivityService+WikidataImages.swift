import Foundation
import OSLog

// MARK: - Wikidata Image Resolution

extension CityActivityService {
    func resolveWikidataImages(for activities: [CityActivity]) async -> [CityActivity] {
        let needsImage = activities.filter { $0.imageURL == nil && $0.wikidataIdentifier != nil }
        guard !needsImage.isEmpty else { return activities }

        let ids = needsImage.compactMap(\.wikidataIdentifier)
        let imageMap = await self.wikidataImageMap(for: ids)
        guard !imageMap.isEmpty else { return activities }

        return activities.map { activity in
            guard activity.imageURL == nil,
                  let qid = activity.wikidataIdentifier,
                  let resolvedURL = imageMap[qid]
            else { return activity }

            return CityActivity(
                id: activity.id,
                name: activity.name,
                summary: activity.summary,
                category: activity.category,
                kind: activity.kind,
                imageURL: resolvedURL,
                officialURL: activity.officialURL,
                sourceURL: activity.sourceURL,
                sourceName: activity.sourceName,
                hours: activity.hours,
                price: activity.price,
                address: activity.address,
                directions: activity.directions,
                timingTip: activity.timingTip,
                latitude: activity.latitude,
                longitude: activity.longitude,
                wikidataIdentifier: activity.wikidataIdentifier,
                sourcePageTitle: activity.sourcePageTitle,
                sourceAnchor: activity.sourceAnchor
            )
        }
    }

    func wikidataImageMap(for ids: [String]) async -> [String: URL] {
        let joined = Array(ids.prefix(50)).joined(separator: "|")

        var components = URLComponents(string: "https://www.wikidata.org/w/api.php")
        components?.queryItems = [
            URLQueryItem(name: "action", value: "wbgetentities"),
            URLQueryItem(name: "ids", value: joined),
            URLQueryItem(name: "props", value: "claims"),
            URLQueryItem(name: "format", value: "json"),
            URLQueryItem(name: "formatversion", value: "2")
        ]

        guard let url = components?.url else { return [:] }

        do {
            let data = try await self.fetchData(from: url)
            let response = try self.decoder.decode(Models.WikidataEntitiesResponse.self, from: data)

            var map: [String: URL] = [:]
            for (qid, entity) in response.entities {
                guard let claims = entity.claims?["P18"],
                      let firstClaim = claims.first,
                      let fileName = firstClaim.mainsnak.datavalue?.value.stringValue
                else { continue }

                let encoded = fileName
                    .replacingOccurrences(of: " ", with: "_")
                    .addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? ""

                if !encoded.isEmpty,
                   let imageURL = URL(string: "https://commons.wikimedia.org/wiki/Special:FilePath/\(encoded)")
                {
                    map[qid] = imageURL
                }
            }
            return map
        } catch {
            self.logger.debug("Wikidata image fetch failed: \(error.localizedDescription, privacy: .public)")
            return [:]
        }
    }
}
