import SwiftUI

/// Chooses the time zone a departure time is entered in.
///
/// Choosing a listed departure airport sets this automatically; the picker is
/// for airports outside the directory.
struct FlightTimeZonePicker: View {
    @Environment(\.dismiss) private var dismiss
    let selection: String
    /// The departure, so each offset is the one in effect that day.
    let referenceDate: Date
    let onSelect: (String) -> Void

    @State private var options: [FlightTimeZoneOption] = []
    @State private var query = ""

    var body: some View {
        List(FlightTimeZoneCatalog.filter(options, matching: query)) { option in
            Button {
                onSelect(option.id)
                dismiss()
            } label: {
                FlightPickerRow(
                    title: option.city, subtitle: option.name, detail: option.offset,
                    isSelected: option.id == selection
                )
            }
            .accessibilityAddTraits(option.id == selection ? .isSelected : [])
        }
        .overlay {
            if !query.isEmpty, FlightTimeZoneCatalog.filter(options, matching: query).isEmpty {
                ContentUnavailableView.search(text: query)
            }
        }
        .searchable(text: $query, placement: .navigationBarDrawer(displayMode: .always), prompt: "City, zone, or GMT offset")
        .scrollDismissesKeyboard(.immediately)
        .navigationTitle("Time Zone")
        .navigationBarTitleDisplayMode(.inline)
        .task { options = FlightTimeZoneCatalog.options(at: referenceDate) }
    }
}
