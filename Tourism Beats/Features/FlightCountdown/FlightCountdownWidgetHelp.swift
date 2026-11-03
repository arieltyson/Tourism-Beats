import SwiftUI

struct FlightCountdownWidgetHelp: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            List {
                Section {
                    Text("Touch and hold your Home Screen, then choose Edit → Add Widget.")
                    Text("Search for Tourism Beats and choose Flight Countdown.")
                    Text("Choose a size, then tap Add Widget.")
                } footer: {
                    Text("Your widget shows the next scheduled flight. Tap it to open Flight Countdown.")
                }
            }
            .navigationTitle("Add a Widget")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}
