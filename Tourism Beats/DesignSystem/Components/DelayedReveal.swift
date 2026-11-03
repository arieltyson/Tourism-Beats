import SwiftUI

/// Shows its content only once a wait is long enough to notice, so quick
/// loads never flash a loading indicator.
struct DelayedReveal<Content: View>: View {
    @ViewBuilder let content: Content
    @State private var isVisible = false

    var body: some View {
        content
            .opacity(isVisible ? 1 : 0)
            .task {
                do {
                    try await Task.sleep(for: ImageLoadingTokens.spinnerDelay)
                    isVisible = true
                } catch {
                    // The wait ended first; nothing to show.
                }
            }
    }
}
