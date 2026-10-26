import SwiftUI

// MARK: - TripStatusSection

struct TripStatusSection: View {
    @Binding var status: TripStatus

    var body: some View {
        Section {
            Picker("Status", selection: self.$status) {
                ForEach(TripStatus.allCases) { tripStatus in
                    Label(tripStatus.label, systemImage: tripStatus.systemImage)
                        .tag(tripStatus)
                }
            }
            .pickerStyle(.segmented)
        } header: {
            Text("Status")
        }
    }
}
