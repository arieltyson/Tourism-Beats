import SwiftUI

struct FlightTimeZonePicker: View {
    @Environment(\.dismiss) private var dismiss
    @Bindable var form: FlightCountdownFormViewModel

    var body: some View {
        List(form.matchingTimeZones, id: \.self) { identifier in
            Button {
                form.timeZoneIdentifier = identifier
                dismiss()
            } label: {
                HStack(spacing: SpacingTokens.small) {
                    Text(FlightCountdownFormViewModel.label(for: identifier))
                        .foregroundStyle(.primary)
                    Spacer(minLength: SpacingTokens.small)
                    if identifier == form.timeZoneIdentifier {
                        Image(systemName: "checkmark")
                            .accessibilityHidden(true)
                    }
                }
            }
            .accessibilityAddTraits(identifier == form.timeZoneIdentifier ? .isSelected : [])
        }
        .searchable(text: $form.timeZoneQuery, prompt: "City or time zone")
        .navigationTitle("Departure Time Zone")
        .navigationBarTitleDisplayMode(.inline)
    }
}
