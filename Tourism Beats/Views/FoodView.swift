import SwiftData
import SwiftUI

// MARK: - FoodView

struct FoodView: View {
    private static let navigationSubtitle = "Save your favourite restaurants & meals."

    @Query(sort: \Restaurant.dateAdded, order: .reverse)
    private var restaurants: [Restaurant]

    @Environment(\.modelContext) private var modelContext
    @State private var viewModel = FoodViewModel()

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: SpacingTokens.medium) {
                FoodJournalHeader(
                    title: "Food Journal",
                    subtitle: Self.navigationSubtitle
                )
                .padding(.horizontal, SpacingTokens.medium)

                if let showcase = self.viewModel.visibleShowcase {
                    FoodShowcaseContent(showcase: showcase, gastroCities: self.viewModel.gastroCities)
                        .padding([.horizontal, .bottom], SpacingTokens.medium)
                } else if self.restaurants.isEmpty, self.viewModel.searchText.isEmpty {
                    // Adding lives in the toolbar alone; the empty journal
                    // offers something to explore instead of a second button.
                    FoodEmptyState()
                        .padding([.horizontal, .bottom], SpacingTokens.medium)
                } else {
                    FoodJournalContent(
                        cityGroups: self.viewModel.cityGroups(from: self.restaurants),
                        searchText: self.viewModel.searchText,
                        onEdit: { restaurant in
                            self.viewModel.restaurantToEdit = restaurant
                        },
                        onDelete: { restaurant in
                            self.deleteRestaurant(restaurant)
                        }
                    )
                }
            }
            .padding(.top, SpacingTokens.small)
        }
        .scrollIndicators(.hidden)
        .background(Color.clear.ignoresSafeArea())
        .navigationDestination(for: CityModel.self) { city in
            CityContainerView(city: city)
        }
        .navigationTitle("")
        .toolbar(removing: .title)
        .toolbarTitleDisplayMode(.inline)
        .searchable(
            text: self.$viewModel.searchText,
            placement: .toolbar,
            prompt: "Search cities or restaurants"
        )
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                FoodJournalFilterMenu(viewModel: self.viewModel)
            }

            ToolbarItem(placement: .topBarTrailing) {
                Button("Add Restaurant", systemImage: "plus") {
                    self.viewModel.isAddSheetPresented = true
                }
            }
        }
        .sheet(isPresented: self.$viewModel.isAddSheetPresented) {
            AddEditRestaurantView(
                placeOptions: self.viewModel.placeOptions(from: self.restaurants)
            )
        }
        .sheet(item: self.$viewModel.restaurantToEdit) { restaurant in
            AddEditRestaurantView(
                restaurant: restaurant,
                placeOptions: self.viewModel.placeOptions(from: self.restaurants)
            )
        }
    }

    private func deleteRestaurant(_ restaurant: Restaurant) {
        let deletedPaths = restaurant.sortedMealPhotos.map(\.relativePath)

        withAnimation(AnimationTokens.standard) {
            self.modelContext.delete(restaurant)
        }

        Task {
            try? await RestaurantMealPhotoStore.shared.deleteFiles(at: deletedPaths)
        }
    }
}

// MARK: - FoodShowcaseContent

/// A world food ranking shown in place of the journal.
private struct FoodShowcaseContent: View {
    let showcase: FoodShowcase
    let gastroCities: [FeaturedGastroCity]

    var body: some View {
        switch self.showcase {
        case .topCuisines:
            WorldCuisineRankingSection(cuisines: WorldCuisineRanking.top, source: WorldCuisineRanking.source)
        case .gastroCities:
            GastroCityRankingSection(cities: self.gastroCities)
        }
    }
}

// MARK: - FoodJournalHeader

private struct FoodJournalHeader: View {
    let title: String
    let subtitle: String

    var body: some View {
        VStack(alignment: .leading, spacing: SpacingTokens.xxSmall) {
            Text(self.title)
                .font(TypographyTokens.heroTitle.weight(.bold))
                .foregroundStyle(.primary)
                .accessibilityAddTraits(.isHeader)

            Text(self.subtitle)
                .font(TypographyTokens.body)
                .foregroundStyle(.secondary)
                .italic()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

// MARK: - FoodJournalContent

private struct FoodJournalContent: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    let cityGroups: [FoodJournalCityGroup]
    let searchText: String
    let onEdit: (Restaurant) -> Void
    let onDelete: (Restaurant) -> Void

    var body: some View {
        LazyVStack(spacing: SpacingTokens.medium) {
            if self.cityGroups.isEmpty {
                FoodNoResults(searchText: self.searchText)
                    .padding(.top, SpacingTokens.xxLarge)
            } else {
                ForEach(self.cityGroups.enumerated(), id: \.element.id) { index, group in
                    NavigationLink {
                        FoodCityJournalView(
                            group: group,
                            onEdit: self.onEdit,
                            onDelete: self.onDelete
                        )
                    } label: {
                        FoodCityCard(group: group)
                    }
                    .buttonStyle(.plain)
                    .transition(
                        self.reduceMotion
                            ? .opacity
                            : .opacity.combined(with: .scale(scale: 0.98))
                    )
                    .motionSensitiveAnimation(
                        AnimationTokens.stagger(index: index),
                        reduced: .linear(duration: 0.01),
                        value: self.cityGroups.count
                    )
                }
            }
        }
        .padding(.horizontal, SpacingTokens.medium)
        .padding(.vertical, SpacingTokens.small)
    }
}

// MARK: - FoodNoResults

private struct FoodNoResults: View {
    let searchText: String

    var body: some View {
        VStack(spacing: SpacingTokens.medium) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 40))
                .foregroundStyle(.tertiary)

            Text("No saved cities or restaurants match \"\(self.searchText)\"")
                .font(TypographyTokens.body)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(SpacingTokens.xLarge)
    }
}
