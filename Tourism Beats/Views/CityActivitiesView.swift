import SwiftUI

// MARK: - CityActivitiesView

struct CityActivitiesView: View {
    let city: CityModel

    @State private var viewModel: CityActivitiesViewModel

    init(city: CityModel) {
        self.city = city
        _viewModel = State(initialValue: CityActivitiesViewModel(city: city))
    }

    var body: some View {
        VStack(spacing: SpacingTokens.medium) {
            Self.HeroCard(city: self.city)

            Group {
                if self.viewModel.isLoading, self.viewModel.activities.isEmpty {
                    Self.LoadingState()
                } else if self.viewModel.activities.isEmpty {
                    Self.EmptyState(
                        message: self.viewModel.statusMessage
                            ?? "No activity guide is available for \(self.city.name) right now.",
                        refreshAction: {
                            Task {
                                await self.viewModel.refresh()
                            }
                        }
                    )
                } else {
                    Self.ActivityGrid(
                        city: self.city,
                        activities: self.viewModel.activities
                    )
                }
            }
            .padding(.horizontal, SpacingTokens.xSmall)

            Spacer(minLength: 0)
        }
        .padding(.horizontal, SpacingTokens.medium)
        .padding(.top, SpacingTokens.small)
        .padding(.bottom, SpacingTokens.xxLarge)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .background(Color.clear.ignoresSafeArea())
        .safeAreaPadding(.bottom, SpacingTokens.medium)
        .task(id: self.city.id) {
            await self.viewModel.loadIfNeeded()
        }
    }
}

extension CityActivitiesView {
    private struct HeroCard: View {
        let city: CityModel

        @Environment(\.colorScheme) private var scheme

        var body: some View {
            HStack(alignment: .center, spacing: SpacingTokens.small) {
                ZStack {
                    Circle()
                        .fill(AppColors.gold.opacity(0.24))

                    Image(systemName: "figure.walk.motion")
                        .font(.headline)
                        .foregroundStyle(AppColors.gold)
                }
                .frame(width: 40, height: 40)

                VStack(alignment: .leading, spacing: SpacingTokens.xxSmall) {
                    Text("Top Activities")
                        .font(TypographyTokens.sectionHeader)
                        .bold()
                        .foregroundStyle(AppColors.label)

                    Text("\(self.city.name), \(self.city.country.name)")
                        .font(TypographyTokens.cardLabel)
                        .foregroundStyle(AppColors.secondaryLabel)
                        .lineLimit(2)
                }

                Spacer(minLength: 0)
            }
            .padding(SpacingTokens.medium)
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

    private struct PlaceholderCard: View {
        var body: some View {
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(AppColors.surfaceSecondary.opacity(0.6))
                .frame(maxWidth: .infinity)
                .aspectRatio(4 / 3, contentMode: .fit)
                .phaseAnimator([false, true]) { content, phase in
                    content
                        .opacity(phase ? 0.4 : 0.8)
                } animation: { _ in
                    .easeInOut(duration: 1.0)
                }
        }
    }

    private struct LoadingState: View {
        var body: some View {
            Grid(horizontalSpacing: SpacingTokens.small, verticalSpacing: SpacingTokens.small) {
                GridRow {
                    PlaceholderCard()
                    PlaceholderCard()
                }

                GridRow {
                    PlaceholderCard()
                    PlaceholderCard()
                }

                GridRow {
                    PlaceholderCard()
                    PlaceholderCard()
                }
            }
            .accessibilityHidden(true)
        }
    }

    private struct EmptyState: View {
        let message: String
        let refreshAction: () -> Void

        var body: some View {
            Spacer(minLength: 0)

            ContentUnavailableView {
                Label("No Activities Yet", systemImage: "binoculars")
            } description: {
                Text(self.message)
            } actions: {
                Button("Try Again", action: self.refreshAction)
            }

            Spacer(minLength: 0)
        }
    }

    private struct ActivityGrid: View {
        let city: CityModel
        let activities: [CityActivity]

        var body: some View {
            Grid(horizontalSpacing: SpacingTokens.small, verticalSpacing: SpacingTokens.small) {
                GridRow {
                    CityActivitiesView.CardSlot(city: self.city, activity: self.activity(at: 0))
                    CityActivitiesView.CardSlot(city: self.city, activity: self.activity(at: 1))
                }

                GridRow {
                    CityActivitiesView.CardSlot(city: self.city, activity: self.activity(at: 2))
                    CityActivitiesView.CardSlot(city: self.city, activity: self.activity(at: 3))
                }

                GridRow {
                    CityActivitiesView.CardSlot(city: self.city, activity: self.activity(at: 4))
                    CityActivitiesView.CardSlot(city: self.city, activity: self.activity(at: 5))
                }
            }
        }

        private func activity(at index: Int) -> CityActivity? {
            guard self.activities.indices.contains(index) else { return nil }
            return self.activities[index]
        }
    }

    private struct CardSlot: View {
        let city: CityModel
        let activity: CityActivity?

        var body: some View {
            Group {
                if let activity {
                    NavigationLink(
                        value: CityActivityRoute(city: self.city, activity: activity)
                    ) {
                        ActivityCard(activity: activity)
                    }
                    .buttonStyle(.plain)
                } else {
                    Rectangle()
                        .fill(.clear)
                        .frame(maxWidth: .infinity)
                        .aspectRatio(4 / 3, contentMode: .fit)
                        .accessibilityHidden(true)
                }
            }
        }
    }

    struct ActivityCard: View {
        let activity: CityActivity

        @Environment(\.colorScheme) private var scheme

        var body: some View {
            Color.clear
                .aspectRatio(4 / 3, contentMode: .fit)
                .overlay {
                    Self.ActivityArtwork(activity: self.activity)
                }
                .overlay {
                    LinearGradient(
                        colors: [
                            AppColors.imageScrimTop.opacity(0.02),
                            AppColors.imageScrimMid.opacity(0.52),
                            AppColors.imageScrimBottom
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                }
                .overlay(alignment: .bottomLeading) {
                    Text(self.activity.name)
                        .font(.headline)
                        .bold()
                        .foregroundStyle(AppColors.onImagePrimary)
                        .multilineTextAlignment(.leading)
                        .lineLimit(2)
                        .padding(SpacingTokens.small)
                }
                .clipShape(.rect(cornerRadius: 24, style: .continuous))
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
                .accessibilityElement(children: .ignore)
                .accessibilityLabel(self.activity.name)
                .accessibilityHint("Opens the full activity details")
        }
    }
}

extension CityActivitiesView.ActivityCard {
    private struct ActivityArtwork: View {
        let activity: CityActivity

        var body: some View {
            Group {
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
        }

        private static var placeholder: some View {
            Rectangle()
                .fill(
                    LinearGradient(
                        colors: [
                            AppColors.info.opacity(0.65),
                            AppColors.violet.opacity(0.72),
                            AppColors.magenta.opacity(0.68)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .overlay {
                    Image(systemName: "sparkles.rectangle.stack.fill")
                        .font(.system(.title, design: .rounded))
                        .foregroundStyle(AppColors.onImagePrimary.opacity(0.92))
                }
        }
    }
}
