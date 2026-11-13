import SwiftUI

// MARK: - CityPagerPage

/// One page of the city pager, drawn only once it has been loaded.
///
/// Until then it holds its place with an empty, full-height frame, so the
/// pager's layout never changes when the page arrives.
struct CityPagerPage<Content: View>: View {
    let isLoaded: Bool
    @ViewBuilder let content: Content

    var body: some View {
        if self.isLoaded {
            self.content
        } else {
            Color.clear
        }
    }
}
