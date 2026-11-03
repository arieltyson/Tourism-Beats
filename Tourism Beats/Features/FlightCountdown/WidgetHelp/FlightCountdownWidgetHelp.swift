import CoreGraphics
import SwiftUI

/// Shows the widget as it will look, then how to add it.
struct FlightCountdownWidgetHelp: View {
    @Environment(\.dismiss) private var dismiss
    /// The flight the widget will show, or a sample before there is one.
    let flight: CountdownFlight
    var photo: CGImage?

    var body: some View {
        NavigationStack {
            List {
                Section {
                    FlightWidgetPreview(flight: flight, photo: photo)
                        .frame(maxWidth: .infinity)
                        .listRowBackground(Color.clear)
                }
                Section {
                    ForEach(FlightWidgetStep.allCases) { step in
                        Label {
                            Text(step.instruction)
                        } icon: {
                            Image(systemName: step.systemImage)
                                .foregroundStyle(.tint)
                                .font(.title2)
                        }
                    }
                } footer: {
                    Text("The widget always shows your next flight. Tap it to open Flight Countdown.")
                }
            }
            .navigationTitle("Add a Widget")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button(role: .close) { dismiss() }
                }
            }
        }
    }
}
