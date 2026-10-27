import SwiftUI

// MARK: - FilledImage

/// An image that fills exactly the space it's offered, cropped to it.
///
/// `scaledToFill()` lays an image out larger than its frame. Clipping hides the
/// overflow but SwiftUI still hit-tests it, so a tall photo invisibly covers the
/// controls around it and swallows their taps. Here the image is laid over a
/// clear base that takes the offered size, and only that base is hit-tested,
/// so taps land on the photo's visible area and nowhere else.
struct FilledImage: View {
    let image: Image

    var body: some View {
        Color.clear
            .overlay {
                self.image
                    .resizable()
                    .scaledToFill()
                    .allowsHitTesting(false)
            }
            .clipped()
            .contentShape(.rect)
    }
}
