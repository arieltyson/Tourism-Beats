import SwiftUI

// MARK: - TripDatesSection

struct TripDatesSection: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    @Binding var hasDates: Bool
    @Binding var startDate: Date
    @Binding var endDate: Date

    var body: some View {
        Section {
            Toggle(
                "Set travel dates",
                isOn: self.$hasDates.animation(
                    self.reduceMotion ? .none : AnimationTokens.standard
                )
            )
            .tint(AppColors.coral)

            if self.hasDates {
                DatePicker(
                    "Start",
                    selection: self.$startDate,
                    displayedComponents: .date
                )

                DatePicker(
                    "End",
                    selection: self.$endDate,
                    in: self.startDate...,
                    displayedComponents: .date
                )
            }
        } header: {
            Text("Travel Dates")
        } footer: {
            if self.hasDates {
                Text(
                    "Saving dates automatically creates itinerary days for the range you choose."
                )
            }
        }
    }
}
