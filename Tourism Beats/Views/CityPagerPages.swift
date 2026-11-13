import SwiftUI

// MARK: - CityPagerPages

/// The city's pages, stacked for the vertical pager.
///
/// This view depends only on which pages are loaded, never on the page that
/// is showing, so the pager crossing from one page to the next mid-swipe
/// doesn't rebuild every page while they move.
struct CityPagerPages: View {
    let city: CityModel
    let loadedPages: Set<Int>
    let barInsets: EdgeInsets

    var body: some View {
        // Five fixed pages need stable frames, not lazy height estimates.
        VStack(spacing: 0) {
            CityPagerPage(isLoaded: self.loadedPages.contains(0)) {
                CityView(city: self.city)
            }
            .cityPageFrame(index: 0, barInsets: self.barInsets)

            CityPagerPage(isLoaded: self.loadedPages.contains(1)) {
                MusicView(city: self.city, fallbackView: FallbackMusicView())
            }
            .cityPageFrame(index: 1, barInsets: self.barInsets)

            CityPagerPage(isLoaded: self.loadedPages.contains(2)) {
                AdvisoriesView(city: self.city)
            }
            .cityPageFrame(index: 2, barInsets: self.barInsets)

            CityPagerPage(isLoaded: self.loadedPages.contains(3)) {
                CityActivitiesView(city: self.city)
            }
            .cityPageFrame(index: 3, barInsets: self.barInsets)

            CityPagerPage(isLoaded: self.loadedPages.contains(4)) {
                CityRestaurantsView(city: self.city)
            }
            .cityPageFrame(index: 4, barInsets: self.barInsets)
        }
        .scrollTargetLayout()
    }
}
