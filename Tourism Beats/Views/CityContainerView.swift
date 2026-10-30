import SwiftUI

struct CityContainerView: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    let city: CityModel

    @State private var pageIndex: Int? = 0
    @State private var haptic = HapticTrigger()
    @State private var barInsets = EdgeInsets()

    private let pages = PageDescriptor.defaults

    private var currentPageIndex: Int {
        self.pageIndex ?? 0
    }

    var body: some View {
        ZStack {
            self.backgroundForCurrentPage
                .ignoresSafeArea()
                .onGeometryChange(for: EdgeInsets.self) { proxy in
                    proxy.safeAreaInsets
                } action: { insets in
                    self.barInsets = insets
                }
                .motionSensitiveAnimation(
                    .easeInOut(duration: 0.4),
                    reduced: .linear(duration: 0.01),
                    value: self.currentPageIndex
                )

            ScrollView(.vertical) {
                LazyVStack(spacing: 0) {
                    CityView(city: self.city)
                        .cityPageFrame(index: 0, barInsets: self.barInsets)

                    MusicView(city: self.city, fallbackView: FallbackMusicView())
                        .cityPageFrame(index: 1, barInsets: self.barInsets)

                    AdvisoriesView(city: self.city)
                        .cityPageFrame(index: 2, barInsets: self.barInsets)

                    CityActivitiesView(city: self.city)
                        .cityPageFrame(index: 3, barInsets: self.barInsets)

                    CityRestaurantsView(city: self.city)
                        .cityPageFrame(index: 4, barInsets: self.barInsets)
                }
                .scrollTargetLayout()
            }
            .scrollTargetBehavior(.viewAligned(limitBehavior: .always))
            .scrollPosition(id: self.$pageIndex)
            .scrollIndicators(.hidden)
            .ignoresSafeArea(.container, edges: .vertical)
            // The pager is inset from the screen edges for the page indicator,
            // so its own top edge effect drew a band narrower than the bar.
            // Each page already sits clear of the bar at rest.
            .scrollEdgeEffectHidden(true, for: .top)
            .padding(.horizontal, PageIndicatorTokens.contentInset)
            .navigationDestination(for: CityActivityRoute.self) { route in
                CityActivityDetailView(city: route.city, activity: route.activity)
            }
            .navigationDestination(for: CityRestaurantRoute.self) { route in
                CityRestaurantDetailView(city: route.city, restaurant: route.restaurant)
            }
        }
        // Every city backdrop is a dark gradient designed for light text, so
        // the pages always use the dark appearance. In Light Mode, glass cards
        // would otherwise turn pale and pair dark text with a dark backdrop.
        .environment(\.colorScheme, .dark)
        .overlay(alignment: .trailing) {
            VerticalIconPageIndicator(
                activeIndex: self.currentPageIndex,
                onSelect: { index in
                    self.selectPage(index)
                }
            )
            .padding(.trailing, PageIndicatorTokens.overlayTrailingPadding)
        }
        .sensoryFeedback(self.haptic.feedback, trigger: self.haptic)
        // The guide pages are lazy and sit four and five pages down, so start
        // their fetches on arrival; the pages then join the in-flight requests.
        // The short wait skips the Apple Maps searches when a city is backed out of.
        .task(id: self.city.id) {
            guard (try? await Task.sleep(for: .seconds(1))) != nil else { return }
            await TripSuggestionsViewModel.prefetchGuides(for: self.city)
        }
        .onChange(of: self.currentPageIndex) { oldValue, newValue in
            guard oldValue != newValue else { return }
            self.haptic.fire(.pageChange)
        }
        // The system back button keeps the swipe back to the map, which a
        // custom one disables.
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .principal) {
                Text(self.city.country.flag)
                    .font(.largeTitle)
                    .opacity(self.currentPageIndex != 0 ? 1 : 0)
                    .motionSensitiveAnimation(
                        .easeInOut,
                        reduced: .linear(duration: 0.01),
                        value: self.currentPageIndex
                    )
            }
        }
    }

    // MARK: - Page Selection

    private func selectPage(_ index: Int) {
        guard index != self.currentPageIndex else { return }
        self.pageIndex = index
    }

    // MARK: - Background

    private var backgroundForCurrentPage: some View {
        let all = GradientProvider.gradients
        let base = UInt(bitPattern: self.city.id.hashValue)
        let pageSeedValues: [UInt] = [31, 47, 59, 71, 83]
        let multiplier = pageSeedValues[min(self.currentPageIndex, pageSeedValues.count - 1)]
        let seed = base &* multiplier
        let idx = Int(seed % UInt(all.count))
        return all[idx]
    }
}
