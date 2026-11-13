import SwiftUI

/// Retains visited pages while deferring work for distant, unvisited sections.
struct CityPagerPage<Content: View>: View {
    let index: Int
    let selectedIndex: Int
    @ViewBuilder let content: () -> Content

    @State private var hasLoaded = false

    private var isNearSelection: Bool {
        abs(self.index - self.selectedIndex) <= 1
    }

    var body: some View {
        Group {
            if self.hasLoaded || self.isNearSelection {
                self.content()
            } else {
                Color.clear
            }
        }
        .onChange(of: self.isNearSelection, initial: true) { _, isNear in
            if isNear {
                self.hasLoaded = true
            }
        }
    }
}
