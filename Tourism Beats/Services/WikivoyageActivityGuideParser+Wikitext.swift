import Foundation

// MARK: - Wikitext Templates and Headings

extension WikivoyageActivityGuideParser {
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
}
