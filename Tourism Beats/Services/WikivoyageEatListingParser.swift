import Foundation

// MARK: - WikivoyageEatListingParser

/// Reads the `{{eat}}` listings from a Wikivoyage guide's Eat section.
enum WikivoyageEatListingParser {
    static func listings(from sectionWikitext: String) -> [WikivoyageEatListing] {
        let lines = sectionWikitext.components(separatedBy: .newlines)
        var listings: [WikivoyageEatListing] = []
        var lineIndex = 0

        while lineIndex < lines.count {
            let line = lines[lineIndex]
            lineIndex += 1

            guard let startRange = line.range(of: "{{eat", options: .caseInsensitive) else { continue }

            // A listing usually spans several lines; read until its braces close.
            var templateText = String(line[startRange.upperBound...])
            var braceDelta = 1 + WikivoyageActivityGuideParser.templateBraceDelta(in: templateText)
            while braceDelta > 0, lineIndex < lines.count {
                templateText += "\n\(lines[lineIndex])"
                braceDelta += WikivoyageActivityGuideParser.templateBraceDelta(in: lines[lineIndex])
                lineIndex += 1
            }

            if let listing = self.listing(fromTemplateBody: templateText) {
                listings.append(listing)
            }
        }

        return listings
    }

    private static func listing(fromTemplateBody templateText: String) -> WikivoyageEatListing? {
        var body = templateText.trimmingCharacters(in: .whitespacesAndNewlines)
        if body.hasSuffix("}}") {
            body.removeLast(2)
        }

        var parameters: [String: String] = [:]
        for segment in WikivoyageActivityGuideParser.topLevelTemplateSegments(from: body) {
            guard let separator = WikivoyageActivityGuideParser.firstTopLevelAssignmentIndex(in: segment) else {
                continue
            }
            let key = segment[..<separator].trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
            parameters[key] = segment[segment.index(after: separator)...]
                .trimmingCharacters(in: .whitespacesAndNewlines)
        }

        guard let name = WikivoyageActivityGuideParser.cleanedListingName(parameters["name"]) else {
            return nil
        }

        return WikivoyageEatListing(
            name: name,
            alternateName: WikivoyageActivityGuideParser.cleanedListingName(parameters["alt"]),
            latitude: WikivoyageActivityGuideParser.doubleValue(parameters["lat"]),
            longitude: WikivoyageActivityGuideParser.doubleValue(parameters["long"])
        )
    }
}
