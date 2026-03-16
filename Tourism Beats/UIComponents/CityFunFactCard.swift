import SwiftUI

// MARK: - CityFunFactLayout

private enum CityFunFactLayout {
    static let cardHeight: CGFloat = 196
    static let factLineLimit = 4
}

// MARK: - CityFunFactCard

struct CityFunFactCard: View {
    let city: CityModel

    @Environment(\.colorScheme) private var scheme
    @Environment(\.accessibilityReduceTransparency) private var reduceTransparency

    @State private var viewModel: CityFunFactViewModel

    init(city: CityModel) {
        self.city = city
        _viewModel = State(initialValue: CityFunFactViewModel(city: city))
    }

    var body: some View {
        VStack(alignment: .leading, spacing: SpacingTokens.small) {
            HStack(alignment: .top, spacing: SpacingTokens.small) {
                CityFunFactBadge()

                VStack(alignment: .leading, spacing: SpacingTokens.xxSmall) {
                    Text("Fun Fact")
                        .font(.system(.headline, design: .rounded))
                        .bold()
                        .foregroundStyle(.white)
                }

                Spacer(minLength: 0)

                if self.viewModel.canShowAnotherFact {
                    Button("Another Fact", systemImage: "shuffle") {
                        self.viewModel.showAnotherFact()
                    }
                    .font(TypographyTokens.footnote)
                    .bold()
                    .foregroundStyle(.white)
                    .padding(.horizontal, SpacingTokens.xSmall)
                    .padding(.vertical, SpacingTokens.xxSmall)
                    .background(.white.opacity(0.12), in: Capsule())
                    .buttonStyle(.plain)
                }
            }

            Group {
                if self.viewModel.isLoading, self.viewModel.displayedFact == nil {
                    CityFunFactLoadingState()
                } else if let fact = self.viewModel.displayedFact {
                    CityFunFactContent(fact: fact)
                        .contentTransition(.opacity)
                } else {
                    CityFunFactUnavailableState(city: self.city)
                }
            }
        }
        .padding(SpacingTokens.medium)
        .frame(
            maxWidth: .infinity,
            minHeight: CityFunFactLayout.cardHeight,
            maxHeight: CityFunFactLayout.cardHeight,
            alignment: .topLeading
        )
        .background {
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(self.baseBackgroundStyle)
                .overlay {
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .fill(self.tintOverlayStyle)
                }
        }
        .clipShape(.rect(cornerRadius: 20, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .strokeBorder(
                    AppColors.glassBorder(for: self.scheme),
                    lineWidth: 0.8
                )
        }
        .shadow(
            color: AppColors.glassShadow(for: self.scheme),
            radius: 12,
            y: 6
        )
        .accessibilityElement(children: .contain)
        .accessibilityHint("Shows a quick local fact about \(self.city.name)")
        .task(id: self.city.id) {
            await self.viewModel.loadIfNeeded()
        }
        .animation(.easeInOut(duration: 0.2), value: self.viewModel.isLoading)
        .animation(
            .spring(response: 0.35, dampingFraction: 0.88),
            value: self.viewModel.displayedFact?.text
        )
    }

    private var baseBackgroundStyle: AnyShapeStyle {
        if self.reduceTransparency {
            return AnyShapeStyle(AppColors.surfaceSecondary)
        }

        return AnyShapeStyle(.ultraThinMaterial)
    }

    private var tintOverlayStyle: AnyShapeStyle {
        AnyShapeStyle(
            LinearGradient(
                colors: [
                    .white.opacity(self.reduceTransparency ? 0.06 : 0.12),
                    AppColors.gold.opacity(self.reduceTransparency ? 0.10 : 0.14),
                    AppColors.info.opacity(self.reduceTransparency ? 0.06 : 0.10)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
    }
}

// MARK: - CityFunFactBadge

private struct CityFunFactBadge: View {
    var body: some View {
        ZStack {
            Circle()
                .fill(AppColors.gold.opacity(0.24))

            Image(systemName: "sparkles")
                .font(.headline)
                .foregroundStyle(AppColors.gold)
        }
        .frame(width: 38, height: 38)
        .accessibilityHidden(true)
    }
}

// MARK: - CityFunFactContent

private struct CityFunFactContent: View {
    let fact: CityFunFact

    var body: some View {
        VStack(alignment: .leading, spacing: SpacingTokens.xSmall) {
            Text(self.fact.text)
                .font(TypographyTokens.body)
                .foregroundStyle(.white)
                .lineLimit(CityFunFactLayout.factLineLimit, reservesSpace: true)
                .truncationMode(.tail)

            Spacer(minLength: 0)

            CityFunFactFooter(fact: self.fact)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }
}

// MARK: - CityFunFactFooter

private struct CityFunFactFooter: View {
    let fact: CityFunFact

    var body: some View {
        HStack(spacing: SpacingTokens.xSmall) {
            self.sourceLabel

            Spacer(minLength: 0)

            self.fallbackBadge
        }
    }

    @ViewBuilder
    private var sourceLabel: some View {
        if let sourceURL = self.fact.sourceURL {
            Link("Source: \(self.fact.sourceName)", destination: sourceURL)
                .font(TypographyTokens.footnote)
                .foregroundStyle(.white.opacity(0.72))
                .lineLimit(1)
                .truncationMode(.tail)
        } else {
            Text("Source: \(self.fact.sourceName)")
                .font(TypographyTokens.footnote)
                .foregroundStyle(.white.opacity(0.72))
                .lineLimit(1)
                .truncationMode(.tail)
        }
    }

    @ViewBuilder
    private var fallbackBadge: some View {
        if self.fact.isFallback {
            Text("Offline fallback")
                .font(TypographyTokens.footnote)
                .bold()
                .foregroundStyle(.white.opacity(0.72))
                .padding(.horizontal, SpacingTokens.xSmall)
                .padding(.vertical, 2)
                .background(.white.opacity(0.08), in: Capsule())
                .lineLimit(1)
        }
    }
}

// MARK: - CityFunFactLoadingState

private struct CityFunFactLoadingState: View {
    var body: some View {
        VStack(alignment: .leading, spacing: SpacingTokens.xSmall) {
            ProgressView()
                .tint(.white)

            Text("Loading a quick local detail…")
                .font(TypographyTokens.body)
                .foregroundStyle(.white.opacity(0.88))

            Text("This uses a cached public summary when available.")
                .font(TypographyTokens.footnote)
                .foregroundStyle(.white.opacity(0.68))

            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }
}

// MARK: - CityFunFactUnavailableState

private struct CityFunFactUnavailableState: View {
    let city: CityModel

    var body: some View {
        VStack(alignment: .leading, spacing: SpacingTokens.xSmall) {
            Text("A city fact for \(self.city.name) is not available right now.")
                .font(TypographyTokens.body)
                .foregroundStyle(.white.opacity(0.88))
                .lineLimit(CityFunFactLayout.factLineLimit, reservesSpace: true)
                .truncationMode(.tail)

            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }
}
