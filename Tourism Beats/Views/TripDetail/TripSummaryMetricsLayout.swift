import SwiftUI

// MARK: - TripSummaryMetricsLayout

struct TripSummaryMetricsLayout: View {
    let trip: Trip

    var body: some View {
        ViewThatFits(in: .horizontal) {
            HStack(spacing: SpacingTokens.small) {
                TripSummaryMetricsChips(trip: self.trip)
            }

            Grid(
                alignment: .leading,
                horizontalSpacing: SpacingTokens.small,
                verticalSpacing: SpacingTokens.small
            ) {
                GridRow {
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
                }

                GridRow {
                    TripSummaryMetricChip(
                        title: "Done",
                        value: self.trip.completedActivityCount.formatted(.number),
                        tint: AppColors.safe,
                        systemImage: "checkmark.circle"
                    )
                    .gridCellColumns(2)
                }
            }
        }
    }
}
