import SwiftUI

extension View {
    /// Sets up a scroll view inside one page of the vertical city pager.
    ///
    /// A vertical scroll view bounces even when its content fits, and inside
    /// the pager that bounce takes the swipe meant for the next page. Bouncing
    /// only when the content overflows leaves every swipe to the pager until
    /// the page truly has more to show, such as at large text sizes.
    func cityPageScrolling() -> some View {
        self
            .scrollIndicators(.hidden)
            .scrollBounceBehavior(.basedOnSize)
    }
}
