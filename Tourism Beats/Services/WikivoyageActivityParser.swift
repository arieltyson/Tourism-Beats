import Foundation

// MARK: - WikivoyageActivityParser

struct WikivoyageActivityParser: Sendable {
    func activities(
        from wikitext: String,
        defaultKind: CityActivity.Kind,
        sourcePageTitle: String
    ) -> [CityActivity] {
        var activities: [CityActivity] = []
        var currentCategory = defaultKind == .see ? "Highlights" : "Experiences"
        var bufferedTemplate = ""
        var bufferedCategory = currentCategory
        var bufferedLeadingLine = ""
        var braceDepth = 0
        var isCapturing = false

        for line in wikitext.components(separatedBy: .newlines) {
            if let headingTitle = Self.headingTitle(in: line) {
                currentCategory = headingTitle
            }

            if !isCapturing {
                guard let templateRange = Self.supportedTemplateRange(in: line) else {
                    continue
                }

                bufferedCategory = currentCategory
                bufferedLeadingLine = String(line[..<templateRange.lowerBound])
                bufferedTemplate = String(line[templateRange.lowerBound...])
                braceDepth = Self.braceDepthDelta(in: bufferedTemplate)

                if braceDepth <= 0 {
                    if let activity = self.parseTemplateLine(
                        bufferedTemplate,
                        leadingText: bufferedLeadingLine,
                        category: bufferedCategory,
                        defaultKind: defaultKind,
                        sourcePageTitle: sourcePageTitle
                    ) {
                        activities.append(activity)
                    }

                    bufferedTemplate = ""
                    bufferedLeadingLine = ""
                    braceDepth = 0
                } else {
                    isCapturing = true
                }

                continue
            }

            bufferedTemplate.append("\n")
            bufferedTemplate.append(line)
            braceDepth += Self.braceDepthDelta(in: line)

            guard braceDepth <= 0 else { continue }

            if let activity = self.parseTemplateLine(
                bufferedTemplate,
                leadingText: bufferedLeadingLine,
                category: bufferedCategory,
                defaultKind: defaultKind,
                sourcePageTitle: sourcePageTitle
            ) {
                activities.append(activity)
            }

            bufferedTemplate = ""
            bufferedLeadingLine = ""
            braceDepth = 0
            isCapturing = false
        }

        return Self.uniqued(activities)
    }
}

extension WikivoyageActivityParser {
    private struct ParsedLink: Sendable {
        let displayText: String
        let pageTitle: String?
        let anchor: String?
    }

    private struct ParsedTemplate: Sendable {
        let name: String
        let fields: [String: String]
        let positionalValues: [String]
    }

    private func parseTemplateLine(
        _ rawLine: String,
        leadingText: String,
        category: String,
        defaultKind: CityActivity.Kind,
        sourcePageTitle: String
    ) -> CityActivity? {
        guard let extractedTemplate = Self.firstTemplate(in: rawLine),
              let parsedTemplate = self.parsedTemplate(from: extractedTemplate.template)
        else {
            return nil
        }

        guard let activityKind = self.activityKind(
            for: parsedTemplate,
            defaultKind: defaultKind
        ) else {
            return nil
        }

        let nameValue = parsedTemplate.fields["name"] ?? parsedTemplate.positionalValues.first ?? ""
        let altValue = parsedTemplate.fields["alt"] ?? ""
        let link = Self.firstInternalLink(in: nameValue)
        let displayName = Self.sanitizedText(from: nameValue).nilIfEmpty
            ?? Self.sanitizedText(from: altValue).nilIfEmpty
            ?? link?.displayText

        guard let displayName, !displayName.isEmpty else { return nil }

        let summary = Self.sanitizedText(from: parsedTemplate.fields["content"] ?? "").nilIfEmpty
            ?? Self.sanitizedText(from: extractedTemplate.trailingText).nilIfEmpty
            ?? Self.sanitizedText(from: leadingText).nilIfEmpty
            ?? "More details are available in the source guide."

        let imageURL = Self.commonsImageURL(for: parsedTemplate.fields["image"])
        let officialURL = Self.url(from: parsedTemplate.fields["url"])

        let detailPageTitle = (link?.pageTitle ?? sourcePageTitle).nilIfEmpty
        let detailAnchor = Self.sanitizedText(
            from: link?.anchor ?? parsedTemplate.fields["wikidata"] ?? ""
        ).nilIfEmpty
        let sourceURL = Self.wikivoyageURL(
            pageTitle: detailPageTitle ?? sourcePageTitle,
            anchor: detailAnchor
        )

        let hours = Self.sanitizedText(from: parsedTemplate.fields["hours"] ?? "").nilIfEmpty
        let price = Self.sanitizedText(from: parsedTemplate.fields["price"] ?? "").nilIfEmpty
        let address = Self.sanitizedText(from: parsedTemplate.fields["address"] ?? "").nilIfEmpty
        let directions = Self.sanitizedText(from: parsedTemplate.fields["directions"] ?? "").nilIfEmpty
        let latitude = Double((parsedTemplate.fields["lat"] ?? "").trimmingCharacters(in: .whitespacesAndNewlines))
        let longitude = Double((parsedTemplate.fields["long"] ?? "").trimmingCharacters(in: .whitespacesAndNewlines))
        let timingTip = Self.timingTip(
            summary: summary,
            hours: hours,
            directions: directions
        )

        return CityActivity(
            id: Self.identifier(
                pageTitle: detailPageTitle ?? sourcePageTitle,
                anchor: detailAnchor,
                name: displayName,
                kind: activityKind
            ),
            name: displayName,
            summary: summary,
            category: category,
            kind: activityKind,
            imageURL: imageURL,
            officialURL: officialURL,
            sourceURL: sourceURL,
            sourceName: "Wikivoyage",
            hours: hours,
            price: price,
            address: address,
            directions: directions,
            timingTip: timingTip,
            latitude: latitude,
            longitude: longitude,
            wikidataIdentifier: Self.sanitizedText(
                from: parsedTemplate.fields["wikidata"] ?? ""
            ).nilIfEmpty,
            sourcePageTitle: detailPageTitle,
            sourceAnchor: detailAnchor
        )
    }

    private func parsedTemplate(from rawTemplate: String) -> ParsedTemplate? {
        let tokens = Self.topLevelTokens(in: rawTemplate)
        guard let firstToken = tokens.first else { return nil }

        let templateName = firstToken
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .lowercased()
        guard !templateName.isEmpty else { return nil }

        var fields: [String: String] = [:]
        var positionalValues: [String] = []

        for token in tokens.dropFirst() {
            let trimmedToken = token.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !trimmedToken.isEmpty else { continue }

            if let equalsIndex = trimmedToken.firstIndex(of: "=") {
                let key = trimmedToken[..<equalsIndex]
                    .trimmingCharacters(in: .whitespacesAndNewlines)
                    .lowercased()
                let value = String(trimmedToken[trimmedToken.index(after: equalsIndex)...])
                fields[key] = value
            } else {
                positionalValues.append(trimmedToken)
            }
        }

        return ParsedTemplate(
            name: templateName,
            fields: fields,
            positionalValues: positionalValues
        )
    }

    private func activityKind(
        for template: ParsedTemplate,
        defaultKind: CityActivity.Kind
    ) -> CityActivity.Kind? {
        switch template.name {
        case "see":
            .see
        case "do":
            .do
        case "listing", "marker":
            if let type = template.fields["type"]?
                .trimmingCharacters(in: .whitespacesAndNewlines)
                .lowercased()
            {
                switch type {
                case "see":
                    .see
                case "do":
                    .do
                default:
                    defaultKind
                }
            } else {
                defaultKind
            }
        default:
            nil
        }
    }

    private static func firstTemplate(in source: String)
    -> (template: String, trailingText: String)?
    {
        guard let templateRange = self.supportedTemplateRange(in: source) else {
            return nil
        }

        var index = templateRange.lowerBound
        var depth = 0

        while index < source.endIndex {
            if source[index...].hasPrefix("{{") {
                depth += 1
                index = source.index(index, offsetBy: 2)
                continue
            }

            if source[index...].hasPrefix("}}") {
                depth -= 1
                index = source.index(index, offsetBy: 2)

                if depth == 0 {
                    let template = String(source[templateRange.lowerBound ..< index])
                    let trailingText = String(source[index...])
                    return (template, trailingText)
                }

                continue
            }

            index = source.index(after: index)
        }

        return nil
    }

    private static func supportedTemplateRange(in line: String) -> Range<String.Index>? {
        let candidates = ["{{see", "{{do", "{{listing", "{{marker"]

        return candidates
            .compactMap { line.range(of: $0, options: [.caseInsensitive]) }
            .min { lhs, rhs in
                lhs.lowerBound < rhs.lowerBound
            }
    }

    private static func braceDepthDelta(in text: String) -> Int {
        var delta = 0
        var index = text.startIndex

        while index < text.endIndex {
            if text[index...].hasPrefix("{{") {
                delta += 1
                index = text.index(index, offsetBy: 2)
            } else if text[index...].hasPrefix("}}") {
                delta -= 1
                index = text.index(index, offsetBy: 2)
            } else {
                index = text.index(after: index)
            }
        }

        return delta
    }

    private static func topLevelTokens(in rawTemplate: String) -> [String] {
        let body = rawTemplate
            .dropFirst(2)
            .dropLast(2)

        var tokens: [String] = []
        var currentToken = ""
        var templateDepth = 0
        var bracketDepth = 0
        var index = body.startIndex

        while index < body.endIndex {
            if body[index...].hasPrefix("{{") {
                templateDepth += 1
                currentToken.append(contentsOf: "{{")
                index = body.index(index, offsetBy: 2)
                continue
            }

            if body[index...].hasPrefix("}}"), templateDepth > 0 {
                templateDepth -= 1
                currentToken.append(contentsOf: "}}")
                index = body.index(index, offsetBy: 2)
                continue
            }

            if body[index...].hasPrefix("[[") {
                bracketDepth += 1
                currentToken.append(contentsOf: "[[")
                index = body.index(index, offsetBy: 2)
                continue
            }

            if body[index...].hasPrefix("]]"), bracketDepth > 0 {
                bracketDepth -= 1
                currentToken.append(contentsOf: "]]")
                index = body.index(index, offsetBy: 2)
                continue
            }

            let character = body[index]

            if character == "[", !body[index...].hasPrefix("[[") {
                bracketDepth += 1
                currentToken.append(character)
                index = body.index(after: index)
                continue
            }

            if character == "]", bracketDepth > 0 {
                bracketDepth -= 1
                currentToken.append(character)
                index = body.index(after: index)
                continue
            }

            if character == "|", templateDepth == 0, bracketDepth == 0 {
                tokens.append(currentToken)
                currentToken = ""
                index = body.index(after: index)
                continue
            }

            currentToken.append(character)
            index = body.index(after: index)
        }

        tokens.append(currentToken)
        return tokens
    }

    private static func headingTitle(in line: String) -> String? {
        let trimmed = line.trimmingCharacters(in: .whitespacesAndNewlines)
        let prefixEquals = trimmed.prefix { $0 == "=" }.count
        let suffixEquals = trimmed.reversed().prefix { $0 == "=" }.count

        guard prefixEquals >= 2, prefixEquals == suffixEquals else {
            return nil
        }

        let title = trimmed
            .dropFirst(prefixEquals)
            .dropLast(suffixEquals)
            .trimmingCharacters(in: .whitespacesAndNewlines)

        return title.isEmpty ? nil : title
    }

    private static func firstInternalLink(in text: String) -> ParsedLink? {
        guard let startRange = text.range(of: "[["),
              let endRange = text.range(
                of: "]]",
                range: startRange.upperBound ..< text.endIndex
              )
        else {
            return nil
        }

        let rawLink = String(text[startRange.upperBound ..< endRange.lowerBound])
        let parts = rawLink.split(
            separator: "|",
            maxSplits: 1,
            omittingEmptySubsequences: false
        )
        let rawTarget = String(parts.first ?? "")
        let displayText = self.sanitizedText(
            from: parts.count > 1 ? String(parts[1]) : rawTarget
        )

        let anchorParts = rawTarget.split(
            separator: "#",
            maxSplits: 1,
            omittingEmptySubsequences: false
        )
        let pageTitle = anchorParts.first.map(String.init)?
            .replacingOccurrences(of: "_", with: " ")
            .nilIfEmpty
        let anchor = anchorParts.count > 1 ? String(anchorParts[1]).nilIfEmpty : nil

        return ParsedLink(
            displayText: displayText,
            pageTitle: pageTitle,
            anchor: anchor
        )
    }

    private static func sanitizedText(from rawText: String) -> String {
        var cleaned = rawText

        cleaned = self.removingComments(from: cleaned)
        cleaned = self.replacingTemplates(in: cleaned)
        cleaned = self.replacingExternalLinks(in: cleaned)
        cleaned = self.replacingInternalLinks(in: cleaned)
        cleaned = cleaned
            .replacingOccurrences(of: "'''", with: "")
            .replacingOccurrences(of: "''", with: "")
            .replacingOccurrences(of: "&nbsp;", with: " ")
            .replacingOccurrences(of: "&amp;", with: "&")
            .replacingOccurrences(of: " ,", with: ",")
            .replacingOccurrences(of: " .", with: ".")
            .replacingOccurrences(of: " ;", with: ";")
            .replacingOccurrences(of: " :", with: ":")

        return cleaned
            .split(whereSeparator: \.isWhitespace)
            .joined(separator: " ")
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private static func removingComments(from text: String) -> String {
        var cleaned = text

        while let startRange = cleaned.range(of: "<!--"),
              let endRange = cleaned.range(
                of: "-->",
                range: startRange.upperBound ..< cleaned.endIndex
              )
        {
            cleaned.removeSubrange(startRange.lowerBound ..< endRange.upperBound)
        }

        return cleaned
    }

    private static func replacingTemplates(in text: String) -> String {
        var cleaned = text

        while let startRange = cleaned.range(of: "{{") {
            guard let template = self.firstTemplate(in: String(cleaned[startRange.lowerBound...])) else {
                break
            }

            let replacement = self.simplifiedTemplateText(for: template.template)
            let endIndex = cleaned.index(
                startRange.lowerBound,
                offsetBy: template.template.count
            )
            cleaned.replaceSubrange(startRange.lowerBound ..< endIndex, with: replacement)
        }

        return cleaned
    }

    private static func simplifiedTemplateText(for rawTemplate: String) -> String {
        let tokens = self.topLevelTokens(in: rawTemplate)
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
        guard let name = tokens.first?.lowercased() else { return "" }

        switch name {
        case "iata", "lang", "main", "rint", "station":
            return tokens
                .dropFirst()
                .filter { !$0.contains("=") }
                .map { self.sanitizedText(from: $0) }
                .filter { !$0.isEmpty }
                .joined(separator: " ")
        default:
            return ""
        }
    }

    private static func replacingInternalLinks(in text: String) -> String {
        var cleaned = text

        while let startRange = cleaned.range(of: "[["),
              let endRange = cleaned.range(
                of: "]]",
                range: startRange.upperBound ..< cleaned.endIndex
              )
        {
            let content = String(cleaned[startRange.upperBound ..< endRange.lowerBound])
            let parts = content.split(
                separator: "|",
                maxSplits: 1,
                omittingEmptySubsequences: false
            )
            let replacement = self.sanitizedText(
                from: parts.count > 1 ? String(parts[1]) : String(parts[0])
            )
            cleaned.replaceSubrange(startRange.lowerBound ..< endRange.upperBound, with: replacement)
        }

        return cleaned
    }

    private static func replacingExternalLinks(in text: String) -> String {
        var cleaned = text

        while let startRange = cleaned.range(of: "[http"),
              let endRange = cleaned.range(
                of: "]",
                range: startRange.upperBound ..< cleaned.endIndex
              )
        {
            let content = String(cleaned[startRange.upperBound ..< endRange.lowerBound])
            let parts = content.split(
                separator: " ",
                maxSplits: 1,
                omittingEmptySubsequences: false
            )
            let replacement = parts.count > 1
                ? self.sanitizedText(from: String(parts[1]))
                : ""
            cleaned.replaceSubrange(startRange.lowerBound ..< endRange.upperBound, with: replacement)
        }

        return cleaned
    }

    private static func commonsImageURL(for rawFileName: String?) -> URL? {
        guard let rawFileName else { return nil }
        let fileName = self.sanitizedText(from: rawFileName)
            .replacingOccurrences(of: " ", with: "_")

        guard !fileName.isEmpty,
              let encodedFileName = fileName.addingPercentEncoding(
                withAllowedCharacters: .urlPathAllowed
              )
        else {
            return nil
        }

        return URL(string: "https://commons.wikimedia.org/wiki/Special:FilePath/\(encodedFileName)")
    }

    private static func wikivoyageURL(pageTitle: String, anchor: String?) -> URL? {
        let pathTitle = pageTitle
            .replacingOccurrences(of: " ", with: "_")
        guard let encodedPath = pathTitle.addingPercentEncoding(
            withAllowedCharacters: .urlPathAllowed
        ) else {
            return nil
        }

        var urlString = "https://en.wikivoyage.org/wiki/\(encodedPath)"
        if let anchor, !anchor.isEmpty,
           let encodedAnchor = anchor.addingPercentEncoding(
            withAllowedCharacters: .urlFragmentAllowed
           )
        {
            urlString.append("#\(encodedAnchor)")
        }

        return URL(string: urlString)
    }

    private static func url(from rawValue: String?) -> URL? {
        guard let rawValue else { return nil }
        let sanitized = self.sanitizedText(from: rawValue)
        guard sanitized.hasPrefix("http://") || sanitized.hasPrefix("https://") else {
            return nil
        }
        return URL(string: sanitized)
    }

    private static func timingTip(
        summary: String,
        hours: String?,
        directions: String?
    ) -> String? {
        let timingKeywords = [
            "morning", "afternoon", "evening", "night", "sunrise", "sunset",
            "spring", "summer", "autumn", "fall", "winter",
            "january", "february", "march", "april", "may", "june",
            "july", "august", "september", "october", "november", "december",
            "weekday", "weekend", "daily"
        ]

        let candidates = [summary, hours ?? "", directions ?? ""]
            .joined(separator: ". ")
            .split(separator: ".")
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }

        if let timingSentence = candidates.first(where: { sentence in
            let normalizedSentence = sentence.lowercased()
            return timingKeywords.contains(where: normalizedSentence.localizedStandardContains)
        }), !timingSentence.isEmpty {
            return timingSentence
        }

        if let hours, !hours.isEmpty {
            return "Published hours: \(hours)"
        }

        return nil
    }

    private static func identifier(
        pageTitle: String,
        anchor: String?,
        name: String,
        kind: CityActivity.Kind
    ) -> String {
        let key = [
            pageTitle,
            anchor ?? name,
            kind.rawValue
        ]
        .map(self.normalizedIdentifierComponent)
        .joined(separator: "_")

        return key.isEmpty ? UUID().uuidString : key
    }

    private static func normalizedIdentifierComponent(_ value: String) -> String {
        value
            .folding(
                options: [.caseInsensitive, .diacriticInsensitive],
                locale: .current
            )
            .split { !$0.isLetter && !$0.isNumber }
            .map(String.init)
            .joined(separator: "_")
    }

    private static func uniqued(_ activities: [CityActivity]) -> [CityActivity] {
        var seenIDs: Set<String> = []
        var uniqueActivities: [CityActivity] = []

        for activity in activities where seenIDs.insert(activity.id).inserted {
            uniqueActivities.append(activity)
        }

        return uniqueActivities
    }
}

private extension String {
    var nilIfEmpty: String? {
        self.isEmpty ? nil : self
    }
}
