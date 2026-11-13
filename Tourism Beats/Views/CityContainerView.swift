import SwiftUI

struct CityContainerView: View {
    let city: CityModel

    /// The page the pager shows, updated as soon as a swipe crosses midway.
    @State private var pageIndex: Int? = 0
    /// The page the pager last came to rest on.
    @State private var settledPageIndex = 0
    @State private var loadedPages = CityPagerLoading.pages(
        around: 0,
        pageCount: PageDescriptor.defaults.count
    )
    @State private var haptic = HapticTrigger()
    @State private var barInsets = EdgeInsets()
    @State private var bucketListConfirmation: BucketListConfirmation?

    private var currentPageIndex: Int {
        self.pageIndex ?? 0
    }

    var body: some View {
        ZStack {
            CityPageBackdrop(city: self.city, pageIndex: self.settledPageIndex)
                .ignoresSafeArea()
                .onGeometryChange(for: EdgeInsets.self) { proxy in
                    proxy.safeAreaInsets
                } action: { insets in
                    self.barInsets = insets
                }

            ScrollView(.vertical) {
                CityPagerPages(
                    city: self.city,
                    loadedPages: self.loadedPages,
                    barInsets: self.barInsets
                )
            }
            .scrollTargetBehavior(.viewAligned(limitBehavior: .alwaysByOne))
            .scrollPosition(id: self.$pageIndex)
            .onScrollPhaseChange { _, newPhase in
                if newPhase == .idle {
                    self.settle(on: self.currentPageIndex)
                }
            }
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
        // A sheet's keyboard must not resize the underlying page viewport.
        .ignoresSafeArea(.keyboard)
        .bucketListConfirmation(self.$bucketListConfirmation)
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

            ToolbarItem(placement: .topBarTrailing) {
                CityBucketListButton(city: self.city) { confirmation in
                    self.bucketListConfirmation = confirmation
                }
            }
        }
    }

    // MARK: - Page Selection

    private func selectPage(_ index: Int) {
        guard index != self.currentPageIndex else { return }
        // The jump skips the pages between, so the destination is built
        // before it is shown rather than after it lands.
        self.settle(on: index)
        self.pageIndex = index
    }

    /// Builds the pages around the one the pager rests on, while nothing moves.
    private func settle(on index: Int) {
        self.settledPageIndex = index
        self.loadedPages.formUnion(
            CityPagerLoading.pages(around: index, pageCount: PageDescriptor.defaults.count)
        )
    }
}
