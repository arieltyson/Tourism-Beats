import SwiftUI

// MARK: - BucketListConfirmationModifier

/// Shows a confirmation card over the view for a moment, with a haptic and
/// a VoiceOver announcement, then lets it go.
struct BucketListConfirmationModifier: ViewModifier {
    @Binding var confirmation: BucketListConfirmation?

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    func body(content: Content) -> some View {
        content
            .overlay {
                if let confirmation {
                    BucketListConfirmationCard(confirmation: confirmation)
                        .transition(
                            self.reduceMotion
                                ? .opacity
                                : .scale(scale: 0.85).combined(with: .opacity)
                        )
                }
            }
            .animation(self.reduceMotion ? .linear(duration: AnimationTokens.reducedMotionDuration) : AnimationTokens.snappy, value: self.confirmation)
            .sensoryFeedback(trigger: self.confirmation) { _, newValue in
                guard let newValue else { return nil }
                return newValue.wasAdded ? .success : .impact(weight: .light)
            }
            .task(id: self.confirmation?.id) {
                guard let confirmation else { return }
                AccessibilityAnnouncer.announceBucketList(confirmation)
                guard (try? await Task.sleep(for: BucketListTokens.confirmationDuration)) != nil else { return }
                self.confirmation = nil
            }
    }
}

extension View {
    /// Briefly confirms a place added to or removed from the bucket list.
    func bucketListConfirmation(_ confirmation: Binding<BucketListConfirmation?>) -> some View {
        self.modifier(BucketListConfirmationModifier(confirmation: confirmation))
    }
}
