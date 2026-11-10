import SwiftUI

// MARK: - GastroCityCard

/// A slim banner for a ranked gastronomic capital: its rank, name, and the
/// fact that earns its place, over the city's photo.
struct GastroCityCard: View {
    let gastroCity: FeaturedGastroCity

    @Environment(\.colorScheme) private var colorScheme
    @ScaledMetric(relativeTo: .headline) private var height = FoodJournalTokens.gastroCardHeight

    var body: some View {
        let radius = FoodJournalTokens.gastroCardCornerRadius
        GastroCityCardContent(gastroCity: self.gastroCity)
            .padding(.horizontal, SpacingTokens.medium)
            .padding(.vertical, SpacingTokens.small)
            .frame(maxWidth: .infinity, minHeight: self.height, alignment: .leading)
            .background {
                GastroCityCardBackground(city: self.gastroCity.city)
            }
            .clipShape(.rect(cornerRadius: radius, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: radius, style: .continuous)
                    .strokeBorder(AppColors.glassBorder(for: self.colorScheme), lineWidth: 0.5)
            }
            .cardShadow(cornerRadius: radius, color: AppColors.glassShadow(for: self.colorScheme), radius: 8, y: 4)
            .contentShape(.rect(cornerRadius: radius, style: .continuous))
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(self.gastroCity.accessibilityLabel)
    }
}

// MARK: - GastroCityCardBackground

/// The city's photo, darkened from the leading edge where the text sits.
private struct GastroCityCardBackground: View {
    let city: CityModel

    var body: some View {
        Rectangle()
            .fill(AppColors.violet.gradient)
            .overlay {
                CachedCityImage(url: self.city.imageURL, fallbackCoordinate: self.city.coordinate)
            }
            .overlay {
                LinearGradient(
                    stops: [
                        .init(color: .black.opacity(0.78), location: 0),
                        .init(color: .black.opacity(0.45), location: 0.55),
                        .init(color: .black.opacity(0.15), location: 1)
                    ],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            }
            .clipped()
    }
}

// MARK: - GastroCityCardContent

private struct GastroCityCardContent: View {
    let gastroCity: FeaturedGastroCity

    @ScaledMetric(relativeTo: .title2) private var rankWidth = FoodJournalTokens.gastroRankWidth

    var body: some View {
        HStack(spacing: SpacingTokens.small) {
            Text(self.gastroCity.ranking.rank, format: .number)
                .font(.title2)
                .bold()
                .fontDesign(.rounded)
                .monospacedDigit()
                .foregroundStyle(AppColors.onImagePrimary)
                .frame(minWidth: self.rankWidth, alignment: .leading)

            VStack(alignment: .leading, spacing: SpacingTokens.xxSmall) {
                Text("\(self.gastroCity.city.country.flag) \(self.gastroCity.city.name)")
                    .font(TypographyTokens.sectionHeader)
                    .foregroundStyle(AppColors.onImagePrimary)

                GastroDistinctionLabel(distinction: self.gastroCity.ranking.distinction)
            }

            Spacer(minLength: SpacingTokens.xSmall)

            Image(systemName: "chevron.forward")
                .font(TypographyTokens.caption)
                .bold()
                .foregroundStyle(AppColors.onImageTertiary)
        }
        .shadow(color: .black.opacity(0.3), radius: 4, y: 1)
    }
}

// MARK: - GastroDistinctionLabel

/// The fact that earns the city its place, its symbol in gold.
private struct GastroDistinctionLabel: View {
    let distinction: GastroDistinction

    var body: some View {
        Label {
            Text(self.distinction.text)
                .foregroundStyle(AppColors.onImageSecondary)
        } icon: {
            Image(systemName: self.distinction.systemImage)
                .foregroundStyle(AppColors.gold)
        }
        .font(TypographyTokens.caption)
        .labelStyle(GastroDistinctionLabelStyle())
    }
}

// MARK: - GastroDistinctionLabelStyle

/// A label whose icon sits tight to its text, as a caption's would.
/// Every icon takes the same width, so the facts line up down the list.
private struct GastroDistinctionLabelStyle: LabelStyle {
    @ScaledMetric(relativeTo: .caption) private var iconWidth = FoodJournalTokens.gastroDistinctionIconWidth

    func makeBody(configuration: Configuration) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: SpacingTokens.xxSmall) {
            configuration.icon
                .frame(width: self.iconWidth)
            configuration.title
        }
    }
}
