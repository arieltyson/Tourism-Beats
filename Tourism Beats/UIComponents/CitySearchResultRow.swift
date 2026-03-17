import SwiftUI

// MARK: - CitySearchResultRow

struct CitySearchResultRow: View {
    let city: CityModel
    let searchText: String

    var body: some View {
        HStack(spacing: SpacingTokens.medium) {
            // Country flag
            self.cityIcon

            // City info
            VStack(alignment: .leading, spacing: SpacingTokens.xxSmall) {
                Text(
                    self.highlightedText(
                        self.city.name,
                        searchText: self.searchText
                    )
                )
                .font(TypographyTokens.cardLabel)
                .foregroundStyle(.primary)
                .multilineTextAlignment(.leading)

                Text(self.city.country.name)
                    .font(TypographyTokens.caption)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.leading)
            }

            Spacer()

            Image(systemName: "location.fill")
                .foregroundStyle(AppColors.info)
                .font(TypographyTokens.caption)
        }
        .padding(.horizontal, SpacingTokens.medium)
        .padding(.vertical, SpacingTokens.small)
        .background(
            .quaternary.opacity(0.5),
            in: RoundedRectangle(cornerRadius: 12)
        )
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(self.city.name), \(self.city.country.name)")
        .accessibilityHint("Opens city details")
    }

    private var cityIcon: some View {
        CountryFlagView(
            flagEmoji: self.city.country.flag,
            isoCode: self.city.country.code
        )
        .frame(width: 40, height: 30)
        .accessibilityLabel("\(self.city.country.name) flag")
    }

    private func highlightedText(_ text: String, searchText: String)
    -> AttributedString
    {
        var attributed = AttributedString(text)
        guard !searchText.isEmpty else { return attributed }

        let ranges = text.ranges(of: searchText, options: .caseInsensitive)
        for r in ranges {
            if let ar = Range(r, in: attributed) {
                attributed[ar].backgroundColor = AppColors.searchHighlight
            }
        }
        return attributed
    }
}

// MARK: - CountryFlagView

private struct CountryFlagView: View {
    let flagEmoji: String
    let isoCode: String

    private var resolvedFlag: String {
        let trimmed = self.flagEmoji.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? self.isoCode.flagEmoji : trimmed
    }

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 8).fill(.quaternary)
            Text(self.resolvedFlag)
                .font(.system(size: 18))
                .minimumScaleFactor(0.6)
        }
    }
}

// MARK: - String helpers used by the row

extension String {
    /// All ranges of `searchString` within the string.
    func ranges(of searchString: String, options: String.CompareOptions = [])
    -> [Range<String.Index>]
    {
        var result: [Range<String.Index>] = []
        var start = startIndex
        while start < endIndex,
              let r = range(
                of: searchString,
                options: options,
                range: start ..< endIndex
              )
        {
            result.append(r)
            start = r.upperBound
        }
        return result
    }

    /// ISO-3166 alpha-2 → flag emoji (e.g., "US" → 🇺🇸). Returns 🏳️ when invalid.
    var flagEmoji: String {
        let u = uppercased()
        guard u.count == 2,
              u.unicodeScalars.allSatisfy({ ("A" ... "Z").contains(Character($0)) })
        else { return "🏳️" }
        let base: UInt32 = 0x1F1E6
        var scalars = String.UnicodeScalarView()
        for s in u.unicodeScalars {
            if let regional = UnicodeScalar(base + (s.value - 65)) {
                scalars.append(regional)
            }
        }
        return String(scalars)
    }
}
