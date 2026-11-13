import SwiftUI

// MARK: - CityPageArrivalModifier

/// Settles a page into place as the pager brings it on screen.
///
/// The page grows to full size in step with the swipe that brings it in, so
/// its arrival can never trail behind the gesture, and shrinks back as it
/// leaves. Only its scale changes: scaling moves what is already drawn,
/// while fading a page of glass cards would draw them all again on every
/// frame. With Reduce Motion the page simply slides.
struct CityPageArrivalModifier: ViewModifier {
    /// How large a page is while it's still off screen.
    static let arrivingScale: CGFloat = 0.98

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    func body(content: Content) -> some View {
        content.scrollTransition(.interactive, axis: .vertical) { [reduceMotion] page, phase in
            page.scaleEffect(reduceMotion || phase.isIdentity ? 1 : Self.arrivingScale)
        }
    }
}

extension View {
    /// Settles this page into place as the city pager brings it on screen.
    func cityPageArrival() -> some View {
        self.modifier(CityPageArrivalModifier())
    }
}
