import Foundation

// MARK: - WikivoyageActivityGuideParser

struct WikivoyageActivityGuideParser {
    func activities(
        from sectionWikitext: String,
        guidePageTitle: String,
        topSectionTitle: String
    ) -> [CityActivity] {
        let lines = sectionWikitext.components(separatedBy: .newlines)

        var activities: [CityActivity] = []
        var currentSectionTitle = topSectionTitle
        var lineIndex = 0

        while lineIndex < lines.count {
            let rawLine = lines[lineIndex]
            let trimmedLine = rawLine.trimmingCharacters(in: .whitespacesAndNewlines)

            if let headingTitle = Self.headingTitle(from: trimmedLine) {
                currentSectionTitle = headingTitle
                lineIndex += 1
                continue
            }

            if let templateRange = Self.templateStartRange(in: trimmedLine) {
                var templateText = String(trimmedLine[templateRange.lowerBound...])
                var braceDelta = Self.templateBraceDelta(in: templateText)
                lineIndex += 1

                while braceDelta > 0, lineIndex < lines.count {
                    let nextLine = lines[lineIndex]
                    templateText += "\n\(nextLine)"
                    braceDelta += Self.templateBraceDelta(in: nextLine)
                    lineIndex += 1
                }

                if let activity = Self.activityFromTemplate(
                    templateText,
                    guidePageTitle: guidePageTitle,
                    topSectionTitle: topSectionTitle,
                    currentSectionTitle: currentSectionTitle
                ) {
                    activities.append(activity)
                }
                continue
            }

            if let activity = Self.activityFromBullet(
                trimmedLine,
                guidePageTitle: guidePageTitle,
                topSectionTitle: topSectionTitle,
                currentSectionTitle: currentSectionTitle
            ) {
                activities.append(activity)
            }

            lineIndex += 1
        }

        return Self.deduplicatedActivities(activities)
    }
}

private extension WikivoyageActivityGuideParser {
    static func activityFromTemplate(
        _ templateText: String,
        guidePageTitle: String,
        topSectionTitle: String,
        currentSectionTitle: String
    ) -> CityActivity? {
        guard let kind = self.kindFromTemplate(templateText) else { return nil }

        let parameters = self.templateParameters(from: templateText)
        guard let name = self.cleanedListingName(parameters["name"]) else {
            return nil
        }

        let summary = self.cleanedSummary(
            parameters["content"],
            fallbackName: name,
            sectionTitle: currentSectionTitle,
            kind: kind
        )

        let sourceAnchor = self.anchor(from: currentSectionTitle)
        let wikipediaTitle = self.wikipediaTitle(from: parameters["wikipedia"])

        return CityActivity(
            id: self.identifier(
                prefix: "wikivoyage",
                components: [guidePageTitle, currentSectionTitle, name]
            ),
            name: name,
            summary: summary,
            category: self.category(
                sectionTitle: currentSectionTitle,
                topSectionTitle: topSectionTitle,
                name: name,
                summary: summary,
                kind: kind
            ),
            kind: kind,
            imageURL: nil,
            officialURL: self.url(from: parameters["url"]),
            sourceURL: self.guideURL(for: guidePageTitle, anchor: sourceAnchor),
            sourceName: "Wikivoyage",
            hours: self.cleanedOptionalValue(parameters["hours"]),
            price: self.cleanedOptionalValue(parameters["price"]),
            address: self.cleanedOptionalValue(parameters["address"]),
            directions: self.cleanedOptionalValue(parameters["directions"]),
            timingTip: nil,
            latitude: self.doubleValue(parameters["lat"]),
            longitude: self.doubleValue(parameters["long"]),
            wikidataIdentifier: self.cleanedOptionalValue(parameters["wikidata"]),
            sourcePageTitle: wikipediaTitle,
            sourceAnchor: sourceAnchor
        )
    }

    static func activityFromBullet(
        _ trimmedLine: String,
        guidePageTitle: String,
        topSectionTitle: String,
        currentSectionTitle: String
    ) -> CityActivity? {
        guard trimmedLine.hasPrefix("*"), !trimmedLine.hasPrefix("**") else {
            return nil
        }

        let content = String(
            trimmedLine.drop(while: { $0 == "*" || $0.isWhitespace })
        )
        .trimmingCharacters(in: .whitespacesAndNewlines)
        guard !content.isEmpty, !content.hasPrefix("{{") else { return nil }

        let acceptsSentenceBullets = topSectionTitle.localizedStandardContains("do")
        let name = self.bulletTitle(
            from: content,
            acceptsSentenceBullets: acceptsSentenceBullets
        )
        guard let name else { return nil }

        let summary = self.cleanedSummary(
            content,
            fallbackName: name,
            sectionTitle: currentSectionTitle,
            kind: self.kind(from: topSectionTitle)
        )
        let sourceAnchor = self.anchor(from: currentSectionTitle)

        return CityActivity(
            id: self.identifier(
                prefix: "wikivoyage",
                components: [guidePageTitle, currentSectionTitle, name]
            ),
            name: name,
            summary: summary,
            category: self.category(
                sectionTitle: currentSectionTitle,
                topSectionTitle: topSectionTitle,
                name: name,
                summary: summary,
                kind: self.kind(from: topSectionTitle)
            ),
            kind: self.kind(from: topSectionTitle),
            imageURL: nil,
            officialURL: nil,
            sourceURL: self.guideURL(for: guidePageTitle, anchor: sourceAnchor),
            sourceName: "Wikivoyage",
            hours: nil,
            price: nil,
            address: nil,
            directions: nil,
            timingTip: nil,
            latitude: nil,
            longitude: nil,
            wikidataIdentifier: nil,
            sourcePageTitle: nil,
            sourceAnchor: sourceAnchor
        )
    }

    static func templateParameters(from templateText: String) -> [String: String] {
        guard
            let startRange = self.templateStartRange(in: templateText)
        else { return [:] }

        var body = String(templateText[startRange.upperBound...])
            .trimmingCharacters(in: .whitespacesAndNewlines)
        if body.hasSuffix("}}") {
            body.removeLast(2)
        }

        var parameters: [String: String] = [:]
        for segment in self.topLevelTemplateSegments(from: body) {
            guard
                let separatorIndex = self.firstTopLevelAssignmentIndex(in: segment)
            else { continue }

            let key = segment[..<separatorIndex]
                .trimmingCharacters(in: .whitespacesAndNewlines)
                .lowercased()
            guard !key.isEmpty else { continue }

            let value = segment[segment.index(after: separatorIndex)...]
                .trimmingCharacters(in: .whitespacesAndNewlines)
            parameters[key] = value
        }

        return parameters
    }

    static func kindFromTemplate(_ templateText: String) -> CityActivity.Kind? {
        let lowercased = templateText.lowercased()
        if lowercased.contains("{{see") { return .see }
        if lowercased.contains("{{do") { return .do }
        return nil
    }

    static func kind(from sectionTitle: String) -> CityActivity.Kind {
        sectionTitle.localizedStandardContains("do") ? .do : .see
    }

    static func templateStartRange(in value: String) -> Range<String.Index>? {
        if let range = value.range(of: "{{see", options: [.caseInsensitive]) {
            return range
        }

        return value.range(of: "{{do", options: [.caseInsensitive])
    }

    static func templateBraceDelta(in value: String) -> Int {
        value.matches(of: /\{\{/).count - value.matches(of: /\}\}/).count
    }

    static func topLevelTemplateSegments(from body: String) -> [String] {
        var segments: [String] = []
        var currentSegment = ""
        var nestedTemplateDepth = 0
        var nestedLinkDepth = 0
        var index = body.startIndex

        while index < body.endIndex {
            let currentCharacter = body[index]
            let nextIndex = body.index(after: index)
            let nextCharacter = nextIndex < body.endIndex ? body[nextIndex] : nil

            switch (currentCharacter, nextCharacter) {
            case ("{", "{"):
                nestedTemplateDepth += 1
                currentSegment.append(currentCharacter)
                currentSegment.append(nextCharacter!)
                index = body.index(after: nextIndex)

            case ("}", "}"):
                nestedTemplateDepth = max(0, nestedTemplateDepth - 1)
                currentSegment.append(currentCharacter)
                currentSegment.append(nextCharacter!)
                index = body.index(after: nextIndex)

            case ("[", "["):
                nestedLinkDepth += 1
                currentSegment.append(currentCharacter)
                currentSegment.append(nextCharacter!)
                index = body.index(after: nextIndex)

            case ("]", "]"):
                nestedLinkDepth = max(0, nestedLinkDepth - 1)
                currentSegment.append(currentCharacter)
                currentSegment.append(nextCharacter!)
                index = body.index(after: nextIndex)

            case ("|", _) where nestedTemplateDepth == 0 && nestedLinkDepth == 0:
                let trimmedSegment = currentSegment.trimmingCharacters(in: .whitespacesAndNewlines)
                if !trimmedSegment.isEmpty {
                    segments.append(trimmedSegment)
                }
                currentSegment.removeAll(keepingCapacity: true)
                index = nextIndex

            default:
                currentSegment.append(currentCharacter)
                index = nextIndex
            }
        }

        let trimmedSegment = currentSegment.trimmingCharacters(in: .whitespacesAndNewlines)
        if !trimmedSegment.isEmpty {
            segments.append(trimmedSegment)
        }

        return segments
    }

    static func firstTopLevelAssignmentIndex(in value: String) -> String.Index? {
        var nestedTemplateDepth = 0
        var nestedLinkDepth = 0
        var index = value.startIndex

        while index < value.endIndex {
            let currentCharacter = value[index]
            let nextIndex = value.index(after: index)
            let nextCharacter = nextIndex < value.endIndex ? value[nextIndex] : nil

            switch (currentCharacter, nextCharacter) {
            case ("{", "{"):
                nestedTemplateDepth += 1
                index = value.index(after: nextIndex)

            case ("}", "}"):
                nestedTemplateDepth = max(0, nestedTemplateDepth - 1)
                index = value.index(after: nextIndex)

            case ("[", "["):
                nestedLinkDepth += 1
                index = value.index(after: nextIndex)

            case ("]", "]"):
                nestedLinkDepth = max(0, nestedLinkDepth - 1)
                index = value.index(after: nextIndex)

            case ("=", _) where nestedTemplateDepth == 0 && nestedLinkDepth == 0:
                return index

            default:
                index = nextIndex
            }
        }

        return nil
    }

    static func headingTitle(from value: String) -> String? {
        guard
            let match = value.wholeMatch(
                of: /={2,6}\s*(.+?)\s*={2,6}/
            )
        else { return nil }

        return self.cleanedWikitext(String(match.output.1))
    }

    static func bulletTitle(
        from value: String,
        acceptsSentenceBullets: Bool
    ) -> String? {
        if let boldMatch = value.firstMatch(of: /'''(.+?)'''/) {
            let title = self.cleanedWikitext(String(boldMatch.output.1))
            return self.cleanedOptionalValue(title)
        }

        if let linkMatch = value.firstMatch(of: /\[\[([^\]|]+)(?:\|([^\]]+))?\]\]/) {
            let linkedText = String(linkMatch.output.2 ?? linkMatch.output.1)
            let title = self.cleanedWikitext(linkedText)
            return self.cleanedOptionalValue(title)
        }

        guard acceptsSentenceBullets else { return nil }

        let firstClause = value
            .split(separator: ":", maxSplits: 1)
            .first
            .map(String.init)?
            .trimmingCharacters(in: .whitespacesAndNewlines)

        guard let firstClause, !firstClause.isEmpty, firstClause.count <= 90 else {
            return nil
        }

        let title = self.cleanedWikitext(firstClause)
            .replacingOccurrences(
                of: #"^(Visit|Explore|Discover|Experience)\s+"#,
                with: "",
                options: .regularExpression
            )
            .replacingOccurrences(of: #"^(the|a|an)\s+"#, with: "", options: [.regularExpression, .caseInsensitive])
            .trimmingCharacters(in: .whitespacesAndNewlines)

        guard let cleanedTitle = self.cleanedOptionalValue(title) else { return nil }
        return self.presentationTitle(for: cleanedTitle)
    }

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
