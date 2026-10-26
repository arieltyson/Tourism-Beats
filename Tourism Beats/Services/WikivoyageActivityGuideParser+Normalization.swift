import Foundation

// MARK: - Value Normalization

extension WikivoyageActivityGuideParser {
    static func cleanedSummary(
        _ rawValue: String?,
        fallbackName: String,
        sectionTitle: String,
        kind: CityActivity.Kind
    ) -> String {
        if let rawValue {
            let cleanedValue = self.cleanedWikitext(rawValue)
            if let cleanedValue = self.cleanedOptionalValue(cleanedValue) {
                return cleanedValue
            }
        }

        let article = kind == .see ? "A" : "An"
        return "\(article) editor-curated \(sectionTitle.lowercased()) highlight in \(fallbackName)."
    }

    static func cleanedOptionalValue(_ rawValue: String?) -> String? {
        guard let rawValue else { return nil }
        let cleanedValue = self.cleanedWikitext(rawValue)
            .trimmingCharacters(in: .whitespacesAndNewlines)
        return cleanedValue.isEmpty ? nil : cleanedValue
    }

    static func cleanedListingName(_ rawValue: String?) -> String? {
        guard var cleanedValue = self.cleanedOptionalValue(rawValue) else { return nil }

        if let artifactRange = cleanedValue.range(
            of: #"\s*\|\s*(?:alt|url|email|address|directions|phone|fax|lat|long|hours|price|content|wikidata|wikipedia)\s*="#,
            options: .regularExpression
        ) {
            cleanedValue = String(cleanedValue[..<artifactRange.lowerBound])
                .trimmingCharacters(in: .whitespacesAndNewlines)
        }

        return cleanedValue.isEmpty ? nil : cleanedValue
    }

    static func cleanedWikitext(_ value: String) -> String {
        var cleanedValue = value
            .replacingOccurrences(of: "<br />", with: " ")
            .replacingOccurrences(of: "<br/>", with: " ")
            .replacingOccurrences(of: "<br>", with: " ")
            .replacingOccurrences(of: #"(?s)\{\{.*?\}\}"#, with: " ", options: .regularExpression)
            .replacingOccurrences(of: #"\[(https?://[^\s\]]+)\s+([^\]]+)\]"#, with: "$2", options: .regularExpression)
            .replacingOccurrences(of: #"\[(https?://[^\]]+)\]"#, with: " ", options: .regularExpression)
            .replacingOccurrences(of: #"\[\[([^\]|]+)\|([^\]]+)\]\]"#, with: "$2", options: .regularExpression)
            .replacingOccurrences(of: #"\[\[([^\]]+)\]\]"#, with: "$1", options: .regularExpression)
            .replacingOccurrences(of: "'''", with: "")
            .replacingOccurrences(of: "''", with: "")
            .replacingOccurrences(of: "&nbsp;", with: " ")
            .replacingOccurrences(of: #"<!--.*?-->"#, with: " ", options: .regularExpression)

        cleanedValue = cleanedValue.replacingOccurrences(
            of: #"\s+"#,
            with: " ",
            options: .regularExpression
        )

        return cleanedValue.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    static func category(
        sectionTitle: String,
        topSectionTitle: String,
        name: String,
        summary: String,
        kind: CityActivity.Kind
    ) -> String {
        let normalizedSectionTitle = sectionTitle.folding(
            options: [.caseInsensitive, .diacriticInsensitive],
            locale: .current
        )

        switch normalizedSectionTitle {
        case let value where value.localizedStandardContains("museum"):
            return "Museum"
        case let value where value.localizedStandardContains("building")
            || value.localizedStandardContains("architecture")
            || value.localizedStandardContains("structure"):
            return "Architecture"
        case let value where value.localizedStandardContains("heritage")
            || value.localizedStandardContains("history"):
            return "Heritage"
        case let value where value.localizedStandardContains("other sights"):
            return "Attraction"
        case let value where value.localizedStandardContains("hiking")
            || value.localizedStandardContains("ski")
            || value.localizedStandardContains("snow")
            || value.localizedStandardContains("outdoor"):
            return "Outdoors"
        case let value where value.localizedStandardContains("festival"):
            return "Festival"
        case let value where value.localizedStandardContains("market"):
            return "Culture"
        case let value where value.localizedStandardContains("music"):
            return "Music"
        case let value where value.localizedStandardContains("sport"):
            return "Sports"
        case let value where value.localizedStandardContains("park")
            || value.localizedStandardContains("garden")
            || value.localizedStandardContains("nature"):
            return "Nature"
        default:
            let fallbackCategory = CityActivityAPIModels.categoryFromText(
                title: "\(topSectionTitle) \(name)",
                extract: summary
            ).category
            if fallbackCategory == "Attraction", kind == .do {
                return "Experience"
            }
            return fallbackCategory
        }
    }

    static func doubleValue(_ rawValue: String?) -> Double? {
        guard let rawValue else { return nil }
        return Double(rawValue.trimmingCharacters(in: .whitespacesAndNewlines))
    }

    static func url(from rawValue: String?) -> URL? {
        guard let cleanedValue = self.cleanedOptionalValue(rawValue) else { return nil }
        return URL(string: cleanedValue, encodingInvalidCharacters: true)
    }

    static func wikipediaTitle(from rawValue: String?) -> String? {
        guard let cleanedValue = self.cleanedOptionalValue(rawValue) else { return nil }
        let title = cleanedValue
            .replacingOccurrences(of: "en:", with: "")
            .replacingOccurrences(of: "_", with: " ")
            .trimmingCharacters(in: .whitespacesAndNewlines)
        return title.isEmpty ? nil : title
    }

    static func guideURL(for pageTitle: String, anchor: String?) -> URL? {
        let encodedTitle = pageTitle
            .replacingOccurrences(of: " ", with: "_")
            .addingPercentEncoding(withAllowedCharacters: .urlPathAllowed)

        guard let encodedTitle else { return nil }

        if let anchor {
            let encodedAnchor = anchor.addingPercentEncoding(withAllowedCharacters: .urlFragmentAllowed)
            return URL(
                string: "https://en.wikivoyage.org/wiki/\(encodedTitle)#\(encodedAnchor ?? anchor)",
                encodingInvalidCharacters: true
            )
        }

        return URL(
            string: "https://en.wikivoyage.org/wiki/\(encodedTitle)",
            encodingInvalidCharacters: true
        )
    }

    static func anchor(from value: String) -> String {
        value
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: " ", with: "_")
    }

    static func deduplicatedActivities(_ activities: [CityActivity]) -> [CityActivity] {
        var seenNames = Set<String>()

        return activities.filter { activity in
            let lookupKey = self.identifier(
                prefix: "activity",
                components: [activity.name]
            )
            return seenNames.insert(lookupKey).inserted
        }
    }

    static func identifier(prefix: String, components: [String]) -> String {
        let normalizedComponents = components.map {
            $0.folding(
                options: [.caseInsensitive, .diacriticInsensitive],
                locale: .current
            )
            .split { !$0.isLetter && !$0.isNumber }
            .map(String.init)
            .joined(separator: "-")
            .lowercased()
        }
        .filter { !$0.isEmpty }

        return ([prefix] + normalizedComponents).joined(separator: "-")
    }

    static func presentationTitle(for title: String) -> String {
        guard let firstCharacter = title.first else { return title }
        return String(firstCharacter).uppercased() + title.dropFirst()
    }
}
