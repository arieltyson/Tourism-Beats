import SwiftData
import SwiftUI

// MARK: - FoodView

struct FoodView: View {
    @Query(sort: \Restaurant.dateAdded, order: .reverse)
    private var restaurants: [Restaurant]

    @Environment(\.modelContext) private var modelContext
    @State private var viewModel = FoodViewModel()

    var body: some View {
        ScrollView {
            if self.restaurants.isEmpty, self.viewModel.searchText.isEmpty {
                FoodEmptyState {
                    self.viewModel.isAddSheetPresented = true
                }
                .padding(.top, SpacingTokens.xxLarge)
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
        .scrollIndicators(.hidden)
        .background(Color.clear.ignoresSafeArea())
        .navigationTitle("Food Journal")
        .searchable(
            text: self.$viewModel.searchText,
            placement: .toolbar,
            prompt: "Search cities or restaurants"
        )
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                FoodJournalFilterMenu(selectedFilter: self.$viewModel.selectedFilter)
            }

            ToolbarItem(placement: .topBarTrailing) {
                Button("Add Restaurant", systemImage: "plus") {
                    self.viewModel.isAddSheetPresented = true
                }
            }
        }
        .sheet(isPresented: self.$viewModel.isAddSheetPresented) {
            AddEditRestaurantView(
                existingCities: self.viewModel.existingCities(from: self.restaurants)
            )
        }
        .sheet(item: self.$viewModel.restaurantToEdit) { restaurant in
            AddEditRestaurantView(
                restaurant: restaurant,
                existingCities: self.viewModel.existingCities(from: self.restaurants)
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

// MARK: - FoodJournalContent

private struct FoodJournalContent: View {
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
                ForEach(self.cityGroups.indices, id: \.self) { index in
                    let group = self.cityGroups[index]

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
                    .transition(.opacity.combined(with: .scale(scale: 0.98)))
                    .animation(AnimationTokens.stagger(index: index), value: self.cityGroups.count)
                }
            }
        }
        .padding(.horizontal, SpacingTokens.medium)
        .padding(.vertical, SpacingTokens.small)
    }
}

// MARK: - FoodJournalFilterMenu

private struct FoodJournalFilterMenu: View {
    @Binding var selectedFilter: RestaurantStatus?

    var body: some View {
        Menu {
            Button {
                self.selectedFilter = nil
            } label: {
                Label(
                    "All",
                    systemImage: self.selectedFilter == nil ? "checkmark" : ""
                )
            }

            ForEach(RestaurantStatus.allCases) { status in
                Button {
                    self.selectedFilter = status
                } label: {
                    Label(
                        status.label,
                        systemImage: self.selectedFilter == status
                            ? "checkmark"
                            : status.systemImage
                    )
                }
            }
        } label: {
            Image(
                systemName: self.selectedFilter == nil
                    ? "line.3.horizontal.decrease.circle"
                    : "line.3.horizontal.decrease.circle.fill"
            )
            .symbolEffect(.bounce, value: self.selectedFilter)
        }
        .accessibilityLabel("Filter restaurants")
    }
}

// MARK: - FoodEmptyState

private struct FoodEmptyState: View {
    let onAdd: () -> Void

    var body: some View {
        VStack(spacing: SpacingTokens.large) {
            Image(systemName: "fork.knife.circle")
                .font(.system(size: 64))
                .foregroundStyle(AppColors.coral.opacity(0.6))
                .symbolEffect(.pulse, options: .repeating)

            VStack(spacing: SpacingTokens.xSmall) {
                Text("Your Food Journal")
                    .font(TypographyTokens.songTitle)
                    .bold()
                    .foregroundStyle(.primary)

                Text("Save restaurants city by city so every trip builds its own food story.")
                    .font(TypographyTokens.body)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: 300)
            }

            Button {
                self.onAdd()
            } label: {
                Label("Add Restaurant", systemImage: "plus")
                    .font(TypographyTokens.cardLabel)
                    .bold()
                    .foregroundStyle(.white)
                    .padding(.horizontal, SpacingTokens.large)
                    .padding(.vertical, SpacingTokens.small)
                    .background(AppColors.coral, in: Capsule())
            }
            .buttonStyle(.plain)
        }
        .frame(maxWidth: .infinity)
        .padding(SpacingTokens.xLarge)
        .accessibilityElement(children: .contain)
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
