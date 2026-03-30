import SwiftUI

// MARK: - CityActivityDetailView

struct CityActivityDetailView: View {
    let city: CityModel
    let activity: CityActivity

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: SpacingTokens.large) {
                Self.Hero(activity: self.activity, city: self.city)
                Self.PracticalInfoCard(activity: self.activity)
                Self.DescriptionCard(activity: self.activity)
                Self.LinkCard(activity: self.activity)
            }
            .padding(.horizontal, SpacingTokens.medium)
            .padding(.vertical, SpacingTokens.medium)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .scrollIndicators(.hidden)
        .background(Color.clear.ignoresSafeArea())
        .navigationTitle(self.activity.name)
        .navigationBarTitleDisplayMode(.inline)
    }
}

extension CityActivityDetailView {
    struct Hero: View {
        let activity: CityActivity
        let city: CityModel

        @Environment(\.colorScheme) private var scheme

        var body: some View {
            VStack(alignment: .leading, spacing: SpacingTokens.medium) {
                Self.HeroArtwork(activity: self.activity)

                VStack(alignment: .leading, spacing: SpacingTokens.xSmall) {
                    Text(self.activity.name)
                        .font(.largeTitle)
                        .bold()
                        .foregroundStyle(AppColors.label)
                        .multilineTextAlignment(.leading)

                    Text("\(self.activity.category) • \(self.city.name), \(self.city.country.name)")
                        .font(TypographyTokens.cardLabel)
                        .foregroundStyle(AppColors.secondaryLabel)
                }
            }
            .padding(SpacingTokens.medium)
            .background {
                RoundedRectangle(cornerRadius: 28, style: .continuous)
                    .fill(.ultraThinMaterial)
                    .overlay {
                        RoundedRectangle(cornerRadius: 28, style: .continuous)
                            .strokeBorder(
                                AppColors.glassBorder(for: self.scheme),
                                lineWidth: 1
                            )
                    }
                    .shadow(
                        color: AppColors.glassShadow(for: self.scheme),
                        radius: 18,
                        y: 12
                    )
            }
        }
    }

    private struct PracticalInfoCard: View {
        let activity: CityActivity

        @Environment(\.colorScheme) private var scheme

        private var rows: [(label: String, value: String)] {
            var result: [(String, String)] = []
            if let price = self.activity.price { result.append(("Cost", price)) }
            if let hours = self.activity.hours { result.append(("Hours", hours)) }
            if let tip = self.activity.timingTip { result.append(("Timing", tip)) }
            if let location = self.activity.locationSummary { result.append(("Location", location)) }
            return result
        }

        var body: some View {
            if !self.rows.isEmpty {
                VStack(alignment: .leading, spacing: SpacingTokens.small) {
                    Text("Plan Your Visit")
                        .font(TypographyTokens.sectionHeader)
                        .bold()
                        .foregroundStyle(AppColors.label)

                    ForEach(Array(self.rows.enumerated()), id: \.offset) { index, row in
                        if index > 0 { Divider() }

                        LabeledContent(row.label) {
                            Text(row.value)
                                .multilineTextAlignment(.trailing)
                        }
                    }
                }
                .font(TypographyTokens.body)
                .foregroundStyle(AppColors.label)
                .padding(SpacingTokens.medium)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background {
                    RoundedRectangle(cornerRadius: 24, style: .continuous)
                        .fill(.ultraThinMaterial)
                        .overlay {
                            RoundedRectangle(cornerRadius: 24, style: .continuous)
                                .strokeBorder(
                                    AppColors.glassBorder(for: self.scheme),
                                    lineWidth: 1
                                )
                        }
                        .shadow(
                            color: AppColors.glassShadow(for: self.scheme),
                            radius: 16,
                            y: 10
                        )
                }
            }
        }
    }

    private struct DescriptionCard: View {
        let activity: CityActivity

        @Environment(\.colorScheme) private var scheme

        var body: some View {
            VStack(alignment: .leading, spacing: SpacingTokens.small) {
                Text("Why Go")
                    .font(TypographyTokens.sectionHeader)
                    .bold()
                    .foregroundStyle(AppColors.label)

                Text(self.activity.summary)
                    .font(TypographyTokens.body)
                    .foregroundStyle(AppColors.label)

                if let directions = self.activity.directions {
                    Text(directions)
                        .font(TypographyTokens.cardLabel)
                        .foregroundStyle(AppColors.secondaryLabel)
                }
            }
            .padding(SpacingTokens.medium)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background {
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .fill(.ultraThinMaterial)
                    .overlay {
                        RoundedRectangle(cornerRadius: 24, style: .continuous)
                            .strokeBorder(
                                AppColors.glassBorder(for: self.scheme),
                                lineWidth: 1
                            )
                    }
                    .shadow(
                        color: AppColors.glassShadow(for: self.scheme),
                        radius: 16,
                        y: 10
                    )
            }
        }
    }

    struct LinkCard: View {
        let activity: CityActivity

        @Environment(\.colorScheme) private var scheme

        private var hasLinks: Bool {
            self.activity.officialURL != nil || self.activity.sourceURL != nil
        }

        var body: some View {
            if self.hasLinks {
                VStack(alignment: .leading, spacing: SpacingTokens.small) {
                    Text("Links")
                        .font(TypographyTokens.sectionHeader)
                        .bold()
                        .foregroundStyle(AppColors.label)

                    if let officialURL = self.activity.officialURL {
                        Link(destination: officialURL) {
                            Self.LinkLabel(
                                title: "Official Site",
                                subtitle: officialURL.host ?? officialURL.absoluteString,
                                systemImage: "safari"
                            )
                        }
                        .buttonStyle(.plain)
                    }

                    if let sourceURL = self.activity.sourceURL {
                        Link(destination: sourceURL) {
                            Self.LinkLabel(
                                title: "Guide Source",
                                subtitle: self.activity.sourceName,
                                systemImage: "book.pages.fill"
                            )
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(SpacingTokens.medium)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background {
                    RoundedRectangle(cornerRadius: 24, style: .continuous)
                        .fill(.ultraThinMaterial)
                        .overlay {
                            RoundedRectangle(cornerRadius: 24, style: .continuous)
                                .strokeBorder(
                                    AppColors.glassBorder(for: self.scheme),
                                    lineWidth: 1
                                )
                        }
                        .shadow(
                            color: AppColors.glassShadow(for: self.scheme),
                            radius: 16,
                            y: 10
                        )
                }
            }
        }
    }
}

extension CityActivityDetailView.Hero {
    private struct HeroArtwork: View {
        let activity: CityActivity

        var body: some View {
            Color.clear
                .aspectRatio(4 / 3, contentMode: .fit)
                .overlay {
                    if let imageURL = self.activity.imageURL {
                        AsyncImage(
                            url: imageURL,
                            transaction: .init(animation: .smooth)
                        ) { phase in
                            switch phase {
                            case .empty:
                                Self.placeholder
                            case let .success(image):
                                image
                                    .resizable()
                                    .scaledToFill()
                            case .failure:
                                Self.placeholder
                            @unknown default:
                                Self.placeholder
                            }
                        }
                    } else {
                        Self.placeholder
                    }
                }
                .clipShape(.rect(cornerRadius: 20, style: .continuous))
        }

        private static var placeholder: some View {
            Rectangle()
                .fill(
                    LinearGradient(
                        colors: [
                            AppColors.info.opacity(0.72),
                            AppColors.violet.opacity(0.82),
                            AppColors.magenta.opacity(0.78)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .overlay {
                    Image(systemName: "map.fill")
                        .font(.system(.largeTitle, design: .rounded))
                        .foregroundStyle(AppColors.onImagePrimary.opacity(0.92))
                }
        }
    }
}

extension CityActivityDetailView.LinkCard {
    private struct LinkLabel: View {
        let title: String
        let subtitle: String
        let systemImage: String

        var body: some View {
            HStack(spacing: SpacingTokens.small) {
                Image(systemName: self.systemImage)
                    .foregroundStyle(AppColors.coral)

                VStack(alignment: .leading, spacing: SpacingTokens.xxSmall) {
                    Text(self.title)
                        .font(TypographyTokens.cardLabel)
                        .bold()
                        .foregroundStyle(AppColors.label)

                    Text(self.subtitle)
                        .font(TypographyTokens.footnote)
                        .foregroundStyle(AppColors.secondaryLabel)
                        .lineLimit(1)
                }

                Spacer(minLength: 0)

                Image(systemName: "arrow.up.right")
                    .foregroundStyle(AppColors.secondaryLabel)
            }
            .padding(.horizontal, SpacingTokens.xSmall)
            .padding(.vertical, SpacingTokens.small)
            .background(
                AppColors.surfaceSecondary.opacity(0.92),
                in: RoundedRectangle(cornerRadius: 16, style: .continuous)
            )
        }
    }
}
