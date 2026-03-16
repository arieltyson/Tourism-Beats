import SwiftData
import SwiftUI

// MARK: - FoodView

/// The main view for the Food Journal tab.
///
/// Displays user-created restaurant entries grouped by city in glass cards.
/// Supports search, status filtering, add/edit sheets, and swipe-to-delete.
struct FoodView: View {
    @Query(sort: \Restaurant.dateAdded, order: .reverse)
    private var restaurants: [Restaurant]

    @Environment(\.modelContext) private var modelContext
    @State private var viewModel = FoodViewModel()

    var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            if self.restaurants.isEmpty, self.viewModel.searchText.isEmpty {
                FoodEmptyState {
                    self.viewModel.isAddSheetPresented = true
                }
                .padding(.top, SpacingTokens.xxLarge)
            } else {
                self.restaurantList
            }
        }
        .background(Color.clear.ignoresSafeArea())
        .navigationTitle("Food Journal")
        .searchable(
            text: self.$viewModel.searchText,
            placement: .toolbar,
            prompt: "Search restaurants"
        )
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                self.filterMenu
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

    // MARK: - Restaurant List

    private var restaurantList: some View {
        let sections = self.viewModel.filteredSections(from: self.restaurants)
        return LazyVStack(spacing: SpacingTokens.large, pinnedViews: .sectionHeaders) {
            if sections.isEmpty {
                FoodNoResults(searchText: self.viewModel.searchText)
                    .padding(.top, SpacingTokens.xxLarge)
            } else {
                ForEach(Array(sections.enumerated()), id: \.element.id) { index, section in
                    Section {
                        ForEach(section.restaurants) { restaurant in
                            Button {
                                self.viewModel.restaurantToEdit = restaurant
                            } label: {
                                RestaurantCard(restaurant: restaurant)
                            }
                            .buttonStyle(.plain)
                            .contextMenu {
                                Button("Edit", systemImage: "pencil") {
                                    self.viewModel.restaurantToEdit = restaurant
                                }
                                Button(
                                    "Delete",
                                    systemImage: "trash",
                                    role: .destructive
                                ) {
                                    self.deleteRestaurant(restaurant)
                                }
                            }
                            .transition(
                                .opacity.combined(with: .scale(scale: 0.98))
                            )
                        }
                    } header: {
                        CitySectionHeader(
                            city: section.city,
                            count: section.restaurants.count
                        )
                    }
                    .animation(
                        AnimationTokens.entrance.delay(Double(index) * 0.06),
                        value: sections.count
                    )
                }
            }
        }
        .padding(.horizontal, SpacingTokens.medium)
        .padding(.vertical, SpacingTokens.small)
    }

    // MARK: - Filter Menu

    private var filterMenu: some View {
        Menu {
            Button {
                self.viewModel.selectedFilter = nil
            } label: {
                Label(
                    "All",
                    systemImage: self.viewModel.selectedFilter == nil
                        ? "checkmark" : ""
                )
            }
            ForEach(RestaurantStatus.allCases) { status in
                Button {
                    self.viewModel.selectedFilter = status
                } label: {
                    Label(
                        status.label,
                        systemImage: self.viewModel.selectedFilter == status
                            ? "checkmark" : status.systemImage
                    )
                }
            }
        } label: {
            Image(
                systemName: self.viewModel.selectedFilter == nil
                    ? "line.3.horizontal.decrease.circle"
                    : "line.3.horizontal.decrease.circle.fill"
            )
            .symbolEffect(.bounce, value: self.viewModel.selectedFilter)
        }
        .accessibilityLabel("Filter restaurants")
    }

    // MARK: - Actions

    private func deleteRestaurant(_ restaurant: Restaurant) {
        withAnimation(AnimationTokens.standard) {
            self.modelContext.delete(restaurant)
        }
    }
}

// MARK: - RestaurantCard

private struct RestaurantCard: View {
    let restaurant: Restaurant
    @Environment(\.colorScheme) private var scheme

    var body: some View {
        VStack(alignment: .leading, spacing: SpacingTokens.xSmall) {
            // Top row: name + status badge
            HStack(alignment: .firstTextBaseline) {
                Text(self.restaurant.name)
                    .font(TypographyTokens.songTitle.weight(.semibold))
                    .foregroundStyle(.primary)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)

                Spacer(minLength: SpacingTokens.xSmall)

                StatusBadge(status: self.restaurant.status)
            }

            // Score row
            if let score = self.restaurant.clampedScore {
                ScoreDotsView(score: score)
            }

            // Best dish
            if let dish = self.restaurant.bestDish,
               !dish.trimmingCharacters(in: .whitespaces).isEmpty
            {
                HStack(spacing: SpacingTokens.xxSmall) {
                    Image(systemName: "fork.knife")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                    Text(dish)
                        .font(TypographyTokens.caption)
                        .foregroundStyle(.secondary)
                        .italic()
                        .lineLimit(1)
                }
            }

            // Notes
            if let notes = self.restaurant.notes,
               !notes.trimmingCharacters(in: .whitespaces).isEmpty
            {
                Text(notes)
                    .font(TypographyTokens.caption)
                    .foregroundStyle(.tertiary)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)
            }
        }
        .padding(SpacingTokens.small)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            .ultraThinMaterial,
            in: .rect(cornerRadius: 16, style: .continuous)
        )
        .overlay {
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .strokeBorder(
                    AppColors.glassBorder(for: self.scheme),
                    lineWidth: 0.5
                )
        }
        .shadow(
            color: AppColors.glassShadow(for: self.scheme),
            radius: 8,
            y: 4
        )
        .accessibilityElement(children: .combine)
        .accessibilityLabel(self.accessibilityDescription)
    }

    private var accessibilityDescription: String {
        var parts = [self.restaurant.name, self.restaurant.status.label]
        if let score = self.restaurant.clampedScore {
            parts.append("\(score) out of 10")
        }
        if let dish = self.restaurant.bestDish, !dish.isEmpty {
            parts.append("Best dish: \(dish)")
        }
        return parts.joined(separator: ", ")
    }
}

// MARK: - StatusBadge

private struct StatusBadge: View {
    let status: RestaurantStatus

    private var badgeColor: Color {
        switch self.status {
        case .wantToTry: AppColors.coral
        case .tried: AppColors.safe
        }
    }

    var body: some View {
        HStack(spacing: SpacingTokens.xxSmall) {
            Image(systemName: self.status.systemImage)
                .font(.caption2)
            Text(self.status.label)
                .font(.caption2.weight(.semibold))
        }
        .foregroundStyle(self.badgeColor)
        .padding(.horizontal, SpacingTokens.xSmall)
        .padding(.vertical, SpacingTokens.xxSmall)
        .background(
            self.badgeColor.opacity(0.15),
            in: Capsule()
        )
    }
}

// MARK: - ScoreDotsView

/// Displays a restaurant score (0–10) as a row of filled and empty circles.
private struct ScoreDotsView: View {
    let score: Int

    var body: some View {
        HStack(spacing: 3) {
            ForEach(1 ... 10, id: \.self) { index in
                Circle()
                    .fill(index <= self.score ? AnyShapeStyle(AppColors.gold) : AnyShapeStyle(.quaternary))
                    .frame(width: 8, height: 8)
            }

            Text("\(self.score)/10")
                .font(.caption2.weight(.medium).monospacedDigit())
                .foregroundStyle(AppColors.gold)
                .padding(.leading, SpacingTokens.xxSmall)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(self.score) out of 10")
    }
}

// MARK: - CitySectionHeader

private struct CitySectionHeader: View {
    let city: String
    let count: Int
    @Environment(\.colorScheme) private var scheme

    var body: some View {
        HStack(spacing: SpacingTokens.xSmall) {
            Text(self.city)
                .font(TypographyTokens.sectionHeader)
                .foregroundStyle(.primary)

            Text("\(self.count)")
                .font(.caption2.weight(.semibold).monospacedDigit())
                .foregroundStyle(.secondary)
                .padding(.horizontal, 6)
                .padding(.vertical, 2)
                .background(.quaternary, in: Capsule())
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.vertical, SpacingTokens.xSmall)
        .padding(.horizontal, SpacingTokens.small)
        .background(
            .ultraThinMaterial,
            in: .rect(cornerRadius: 12, style: .continuous)
        )
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(self.city), \(self.count) restaurants")
        .accessibilityAddTraits(.isHeader)
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
                    .font(TypographyTokens.songTitle.weight(.semibold))
                    .foregroundStyle(.primary)

                Text("Track restaurants you love and places you want to try in every city you visit.")
                    .font(TypographyTokens.body)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: 300)
            }

            Button {
                self.onAdd()
            } label: {
                Label("Add Restaurant", systemImage: "plus")
                    .font(TypographyTokens.cardLabel.weight(.semibold))
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

            Text("No restaurants match \"\(self.searchText)\"")
                .font(TypographyTokens.body)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(SpacingTokens.xLarge)
    }
}
