import SwiftUI

// MARK: - BucketListEmptyState

/// Fireworks and a nudge, before anything is on the list.
struct BucketListEmptyState: View {
    var body: some View {
        ContentUnavailableView {
            VStack(spacing: SpacingTokens.medium) {
                BucketListFireworks()

                Text("Someday Starts Here")
                    .font(TypographyTokens.songTitle)
                    .bold()
            }
        } description: {
            Text("Tap \(Image(systemName: "plus")) to save the places you dream of and the things you want to do.")
        }
    }
}
