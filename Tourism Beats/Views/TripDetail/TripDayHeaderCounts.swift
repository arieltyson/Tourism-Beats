import SwiftUI

// MARK: - TripDayHeaderCounts

struct TripDayHeaderCounts: View {
    let day: TripDay

    var body: some View {
        HStack(spacing: SpacingTokens.xSmall) {
            TripsInlineCount(
                title: "Done",
                value: self.day.completedActivityCount.formatted(.number),
                tint: AppColors.safe
            )
            TripsInlineCount(
                title: "Pending",
                value: self.day.pendingActivityCount.formatted(.number),
                tint: AppColors.info
            )
        }
    }
}
