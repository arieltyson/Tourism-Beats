import SwiftUI

// MARK: - AdvisoriesView

struct AdvisoriesView: View {
    let city: CityModel

    @State private var showingCountryPicker = false
    @State private var viewModel: AdvisoriesViewModel

    init(city: CityModel) {
        self.city = city
        _viewModel = State(initialValue: AdvisoriesViewModel(city: city))
    }

    var body: some View {
        let content = AdvisoriesContent(
            city: self.city,
            safetyViewModel: self.viewModel.safety,
            visaViewModel: self.viewModel.visa,
            walkabilityViewModel: self.viewModel.walkability,
            showingCountryPicker: self.$showingCountryPicker
        )

        // This page sits inside the vertical city pager, where a page that
        // scrolls itself catches the swipe meant for the next page. So it
        // fits the screen whenever it can: first as it is, then compact, and
        // only when neither fits, at large text sizes, does it scroll.
        ViewThatFits(in: .vertical) {
            content

            content
                .environment(\.advisoriesDensity, .compact)

            ScrollView(.vertical) {
                content
            }
            .cityPageScrolling()
        }
        // Should the cards land while the page is on screen, their
        // placeholders give way to them smoothly, at the size they held.
        .motionSensitiveAnimation(
            AnimationTokens.standard,
            reduced: .linear(duration: AnimationTokens.reducedMotionDuration),
            value: self.viewModel.hasLoaded
        )
        .cityPageArrival()
        // Presentation must outlive the layout selected by ViewThatFits.
        .sheet(isPresented: self.$showingCountryPicker) {
            SearchableCountryPicker(selectedCode: Bindable(self.viewModel.visa).passportCode)
        }
        // The page is built before it comes on screen, so its cards are
        // ready by the time it arrives.
        .task {
            await self.viewModel.load()
        }
        .task(id: self.viewModel.visa.passportCode) {
            await self.viewModel.visa.loadIfNeeded()
        }
    }
}

// MARK: - AdvisoriesContent

/// The page's cards, shared by each of its layouts. The view models belong
/// to the page, so switching layouts never loads anything again.
private struct AdvisoriesContent: View {
    let city: CityModel
    let safetyViewModel: SafetyViewModel
    let visaViewModel: VisaViewModel
    let walkabilityViewModel: WalkabilityViewModel
    @Binding var showingCountryPicker: Bool

    @Environment(\.advisoriesDensity) private var density

    var body: some View {
        VStack(spacing: self.density.cardSpacing) {
            // MARK: Hero

            HeroCard(city: self.city)
                .accessibilityElement(children: .combine)
                .accessibilityLabel(
                    "Travel Advisories for \(self.city.name), \(self.city.country.name)"
                )

            // Safety and visa beside getting around where there's width for
            // both, as on iPhone Duo's unfolded display; one column on a phone.
            AdaptivePanes(alignment: .top, stackSpacing: self.density.cardSpacing) {
                VStack(spacing: self.density.cardSpacing) {
                    // MARK: Safety

                    AdvisoryCard {
                        SectionHeader(
                            title: "Safety Advisory",
                            subtitle: "Global Peace Index 2026"
                        )
                        .padding(.bottom, 2)

                        SafetyView(viewModel: self.safetyViewModel)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .accessibilityHint(
                        "Shows travel advisories for \(self.city.name)"
                    )

                    // MARK: Visa

                    AdvisoryCard {
                        SectionHeader(
                            title: "Visa Entry",
                            subtitle: "Verify with the passport of your choice"
                        )
                        .padding(.bottom, 2)

                        VisaView(
                            viewModel: self.visaViewModel,
                            showingCountryPicker: self.$showingCountryPicker
                        )
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .accessibilityHint(
                        "Shows visa information for travelers to \(self.city.name)"
                    )
                }
            } trailing: {
                // MARK: Getting Around

                AdvisoryCard {
                    SectionHeader(
                        title: "Getting Around",
                        subtitle: "Walk Score\u{00AE} Index"
                    )
                    .padding(.bottom, 2)

                    WalkabilityView(viewModel: self.walkabilityViewModel)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .accessibilityHint(
                    "Shows walkability and transit scores for \(self.city.name)"
                )
            }
        }
        .padding(.horizontal, SpacingTokens.medium)
        .padding(.top, SpacingTokens.small)
        .padding(.bottom, SpacingTokens.medium)
        .environment(\.showsWalkabilityDetail, self.density.showsWalkabilityDetail)
    }
}

// MARK: - HeroCard

private struct HeroCard: View {
    let city: CityModel
    @Environment(\.colorScheme) private var scheme
    @Environment(\.advisoriesDensity) private var density

    var body: some View {
        HStack(spacing: SpacingTokens.small) {
            VStack(alignment: .leading, spacing: 4) {
                Text(self.city.name)
                    .font(.system(.title, design: .rounded).weight(.bold))
                    .foregroundStyle(.primary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)

                Text(self.city.country.name)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }

            Spacer(minLength: 0)

            // Animated walking figure
            WalkingStickman(height: 36, color: .green)
                .padding(8)
                .background(
                    Color.green.opacity(0.1),
                    in: RoundedRectangle(cornerRadius: 12, style: .continuous)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .strokeBorder(Color.green.opacity(0.2), lineWidth: 1)
                )
        }
        .padding(self.density.cardPadding)
        .background {
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .strokeBorder(
                            AppColors.glassBorder(for: self.scheme),
                            lineWidth: 1
                        )
                )
                .shadow(
                    color: AppColors.glassShadow(for: self.scheme),
                    radius: 14,
                    y: 8
                )
        }
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(.isHeader)
    }
}

// MARK: - AdvisoryCard

/// A glass card on the page. The cards move with the page rather than fading
/// as it scrolls: fading a blurred card renders it again on every frame.
private struct AdvisoryCard<Content: View>: View {
    @Environment(\.colorScheme) private var scheme
    @Environment(\.advisoriesDensity) private var density
    @ViewBuilder var content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: self.density.cardContentSpacing) {
            self.content
        }
        .padding(self.density.cardPadding)
        .background {
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .strokeBorder(
                            AppColors.glassBorder(for: self.scheme),
                            lineWidth: 1
                        )
                )
                .shadow(
                    color: AppColors.glassShadow(for: self.scheme),
                    radius: 14,
                    y: 8
                )
        }
        .accessibilityElement(children: .contain)
    }
}

// MARK: - SectionHeader

private struct SectionHeader: View {
    let title: String
    var subtitle: String?

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(self.title)
                .font(.system(.title3, design: .rounded).weight(.semibold))
                .foregroundStyle(.primary)
                .accessibilityAddTraits(.isHeader)

            if let subtitle {
                Text(subtitle)
                    .font(TypographyTokens.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}
