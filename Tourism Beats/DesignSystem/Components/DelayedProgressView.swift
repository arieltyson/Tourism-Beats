import SwiftUI

/// A spinner that appears only once a wait is long enough to notice.
struct DelayedProgressView: View {
    var body: some View {
        DelayedReveal { ProgressView() }
    }
}
