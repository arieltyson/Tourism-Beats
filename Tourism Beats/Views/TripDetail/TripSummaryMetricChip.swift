import SwiftUI

// MARK: - TripSummaryMetricChip

struct TripSummaryMetricChip: View {
    let title: String
    let value: String
    let tint: Color
    let systemImage: String

    var body: some View {
        TripsMetricChip(
            title: self.title,
            value: self.value,
            tint: self.tint,
            systemImage: self.systemImage
        )
    }
}
