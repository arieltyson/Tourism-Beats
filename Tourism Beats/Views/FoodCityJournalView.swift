import SwiftData
import SwiftUI

// MARK: - FoodCityJournalView

struct FoodCityJournalView: View {
    @Environment(\.dismiss) private var dismiss

    let group: FoodJournalCityGroup
    let onEdit: (Restaurant) -> Void
    let onDelete: (Restaurant) -> Void

    @Query(sort: \Restaurant.dateAdded, order: .reverse)
    private var restaurants: [Restaurant]

    private var cityRestaurants: [Restaurant] {
        self.restaurants.filter { self.group.contains($0) }
    }

    var body: some View {
        ScrollView {
            LazyVStack(spacing: SpacingTokens.large) {
                FoodCityJournalHeader(
                    group: self.group,
                    restaurantCount: self.cityRestaurants.count
                )

                if self.cityRestaurants.isEmpty {
                    FoodCityJournalEmptyState(group: self.group)
                } else {
                    ForEach(self.cityRestaurants) { restaurant in
                        Button {
                            self.onEdit(restaurant)
                        } label: {
                            FoodRestaurantCard(
                                restaurant: restaurant,
                                mealPhotos: restaurant.sortedMealPhotos
                            )
                        }
                        .buttonStyle(.plain)
                        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                            Button("Delete", systemImage: "trash", role: .destructive) {
                                self.onDelete(restaurant)
                            }
                        }
                        .contextMenu {
                            Button("Edit", systemImage: "pencil") {
                                self.onEdit(restaurant)
                            }

                            Button(
                                "Delete",
                                systemImage: "trash",
                                role: .destructive
                            ) {
                                self.onDelete(restaurant)
                            }
                        }
                    }
                }
            }
            .padding(.horizontal, SpacingTokens.medium)
            .padding(.vertical, SpacingTokens.small)
        }
        .scrollIndicators(.hidden)
        .background(Color.clear.ignoresSafeArea())
        .navigationTitle(self.group.displayCityName)
        .navigationBarTitleDisplayMode(.inline)
        .onChange(of: self.cityRestaurants.count) { oldCount, newCount in
            guard oldCount > 0, newCount == 0 else { return }
            self.dismiss()
        }
    }
}

// MARK: - FoodCityJournalHeader

private struct FoodCityJournalHeader: View {
    let group: FoodJournalCityGroup
    let restaurantCount: Int

    var body: some View {
        HStack(alignment: .center, spacing: SpacingTokens.medium) {
            FoodCityJournalHeaderArtwork(group: self.group)

            VStack(alignment: .leading, spacing: SpacingTokens.xxSmall) {
                Text(self.group.displayCityName)
                    .font(TypographyTokens.songTitle)
                    .bold()
                    .foregroundStyle(.primary)
                    .lineLimit(2)

                if !self.group.displayCountryName.isEmpty {
                    Text(self.group.displayCountryName)
                        .font(TypographyTokens.artistName)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }

                Text(
                    self.restaurantCount == 1
                        ? "1 saved restaurant"
                        : "\(self.restaurantCount.formatted(.number)) saved restaurants"
                )
                .font(TypographyTokens.caption)
                .foregroundStyle(.secondary)
            }

            Spacer(minLength: SpacingTokens.small)
        }
        .padding(SpacingTokens.small)
        .background(.ultraThinMaterial, in: .rect(cornerRadius: 20, style: .continuous))
    }
}

// MARK: - FoodCityJournalHeaderArtwork

private struct FoodCityJournalHeaderArtwork: View {
    let group: FoodJournalCityGroup

    var body: some View {
        Group {
            if let imageURL = self.group.imageURL {
                CachedCityImage(url: imageURL)
            } else {
                LinearGradient(
                    colors: [AppColors.info, AppColors.violet, AppColors.coral],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .overlay {
                    Image(systemName: "fork.knife.circle.fill")
                        .font(.title)
                        .foregroundStyle(.white.opacity(0.34))
                }
            }
        }
        .frame(width: 84, height: 84)
        .clipShape(.rect(cornerRadius: 18, style: .continuous))
    }
}

// MARK: - FoodCityJournalEmptyState

private struct FoodCityJournalEmptyState: View {
    let group: FoodJournalCityGroup

    var body: some View {
        VStack(spacing: SpacingTokens.small) {
            Image(systemName: "fork.knife.circle")
                .font(.system(size: 44))
                .foregroundStyle(.tertiary)

            Text("No restaurants saved for \(self.group.displayCityName)")
                .font(TypographyTokens.body)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(SpacingTokens.xLarge)
    }
}
