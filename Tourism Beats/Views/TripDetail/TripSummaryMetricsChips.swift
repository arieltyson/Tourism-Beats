import SwiftUI

// MARK: - TripSummaryMetricsChips

struct TripSummaryMetricsChips: View {
    let trip: Trip

    var body: some View {
        Group {
            TripSummaryMetricChip(
                title: "Days",
                value: self.trip.dayCount.formatted(.number),
                tint: AppColors.info,
                systemImage: "calendar"
            )
            TripSummaryMetricChip(
                title: "Activities",
                value: self.trip.activityCount.formatted(.number),
                tint: AppColors.coral,
                systemImage: "list.bullet"
            )
            TripSummaryMetricChip(
                title: "Done",
                value: self.trip.completedActivityCount.formatted(.number),
                tint: AppColors.safe,
                systemImage: "checkmark.circle"
            )
        }
    }
}
