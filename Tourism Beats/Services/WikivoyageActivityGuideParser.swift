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

extension WikivoyageActivityGuideParser {
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
}
