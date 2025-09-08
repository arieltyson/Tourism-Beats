import SwiftUI

struct AdvisoriesView: View {
    let city: CityModel

    @State private var appeared = false

    var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(spacing: 12) {
                // MARK: Hero
                HeroCard(city: city)
                    .accessibilityElement(children: .combine)
                    .accessibilityLabel(
                        "Travel Advisories for \(city.name), \(city.country.name)"
                    )

                // MARK: Safety
                AdvisoryCard {
                    SectionHeader(
                        title: "Safety & Advisories"
                    )
                    .padding(.bottom, 2)

                    SafetyView(viewModel: SafetyViewModel(city: city))
                        .fixedSize(horizontal: false, vertical: true)
                        .transition(.opacity.combined(with: .scale))
                }
                .accessibilityHint("Shows travel advisories for \(city.name)")

                // MARK: Visa
                AdvisoryCard {
                    SectionHeader(
                        title: "Visa & Entry"
                    )
                    .padding(.bottom, 2)

                    VisaView(
                        viewModel: VisaViewModel(
                            passportCode: "TT",
                            destinationCode: city.country.code
                        )
                    )
                    .fixedSize(horizontal: false, vertical: true)
                    .transition(.opacity.combined(with: .scale))
                }
                .accessibilityHint(
                    "Shows visa information for travelers to \(city.name)"
                )
            }
            .padding(.horizontal, 20)
            .padding(.top, 12)
            .padding(.bottom, 16)
            .opacity(appeared ? 1 : 0.9)
            .scaleEffect(appeared ? 1 : 0.98)
            .animation(
                .spring(response: 0.6, dampingFraction: 0.85),
                value: appeared
            )
            .onAppear { appeared = true }
        }
        .background(Color.clear.ignoresSafeArea())
        .navigationBarBackButtonHidden(true)
        .safeAreaPadding(.bottom, 8)
    }
}

// MARK: - Hero

private struct HeroCard: View {
    let city: CityModel
    @Environment(\.colorScheme) private var scheme

    var body: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text(city.name)
                    .font(.system(.largeTitle, design: .rounded).weight(.bold))
                    .foregroundStyle(.primary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)

                Text(city.country.name)
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }

            Spacer(minLength: 0)

            // Decorative glyph
            Image(systemName: "shield.checkered")
                .font(.system(size: 24, weight: .semibold))
                .foregroundStyle(.blue)
                .symbolRenderingMode(.hierarchical)
                .padding(12)
                .background(
                    .blue.opacity(0.1),
                    in: RoundedRectangle(cornerRadius: 12, style: .continuous)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .strokeBorder(.blue.opacity(0.2), lineWidth: 1)
                )
        }
        .padding(12)
        .background {
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .strokeBorder(
                            .white.opacity(scheme == .dark ? 0.10 : 0.16),
                            lineWidth: 1
                        )
                )
                .shadow(
                    color: .black.opacity(scheme == .dark ? 0.30 : 0.08),
                    radius: 14,
                    y: 8
                )
        }
        .scrollTransition(axis: .vertical) { content, phase in
            content
                .opacity(phase.isIdentity ? 1 : 0.85)
                .scaleEffect(phase.isIdentity ? 1 : 0.98)
        }
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(.isHeader)
    }
}

// MARK: - Reusable Card

private struct AdvisoryCard<Content: View>: View {
    @Environment(\.colorScheme) private var scheme
    @ViewBuilder var content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            content
        }
        .padding(12)
        .background {
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .strokeBorder(
                            .white.opacity(scheme == .dark ? 0.10 : 0.16),
                            lineWidth: 1
                        )
                )
                .shadow(
                    color: .black.opacity(scheme == .dark ? 0.30 : 0.08),
                    radius: 14,
                    y: 8
                )
        }
        .scrollTransition(axis: .vertical) { view, phase in
            view
                .opacity(phase.isIdentity ? 1 : 0.92)
                .scaleEffect(phase.isIdentity ? 1 : 0.995)
        }
        .accessibilityElement(children: .contain)
    }
}

// MARK: - Section Header

private struct SectionHeader: View {
    let title: String

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title)
                .font(.system(.title3, design: .rounded).weight(.semibold))
                .foregroundStyle(.primary)
                .accessibilityAddTraits(.isHeader)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}
