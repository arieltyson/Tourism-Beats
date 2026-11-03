import SwiftUI

/// Arranges a card's photos: one fills it, two sit side by side, three put
/// the first beside the other two, and four share it evenly.
struct FlightPhotoCollage<Tile: View>: View {
    let count: Int
    @ViewBuilder let tile: (Int) -> Tile

    var body: some View {
        let spacing = FlightCountdownStyle.collageSpacing
        switch min(count, FlightCountdownStyle.maximumCollageCount) {
        case ...0:
            EmptyView()
        case 1:
            cell(0)
        case 2:
            HStack(spacing: spacing) { cell(0); cell(1) }
        case 3:
            HStack(spacing: spacing) {
                cell(0)
                VStack(spacing: spacing) { cell(1); cell(2) }
            }
        default:
            VStack(spacing: spacing) {
                HStack(spacing: spacing) { cell(0); cell(1) }
                HStack(spacing: spacing) { cell(2); cell(3) }
            }
        }
    }

    private func cell(_ index: Int) -> some View {
        tile(index).frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
