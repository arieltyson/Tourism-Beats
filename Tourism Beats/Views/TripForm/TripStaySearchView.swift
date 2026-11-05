import SwiftUI

// MARK: - TripStaySearchView

/// Finds the trip's hotel. Opens on the city's hotels, ready to type.
struct TripStaySearchView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var model: TripStaySearchViewModel
    @State private var isSearchPresented = true
    let onSelect: (TripStay) -> Void

    init(area: TripStaySearchArea, onSelect: @escaping (TripStay) -> Void) {
        self._model = State(initialValue: TripStaySearchViewModel(area: area))
        self.onSelect = onSelect
    }

    var body: some View {
        NavigationStack {
            List(self.model.results) { stay in
                Button {
                    self.onSelect(stay)
                    self.dismiss()
                } label: {
                    TripStaySearchResultRow(stay: stay)
                }
            }
            .overlay {
                if self.model.results.isEmpty {
                    TripStaySearchStatus(model: self.model)
                }
            }
            .searchable(
                text: self.$model.query,
                isPresented: self.$isSearchPresented,
                placement: .navigationBarDrawer(displayMode: .always),
                prompt: Text("Hotels in \(self.model.area.cityName)")
            )
            .task(id: self.model.trimmedQuery) {
                await self.model.search()
            }
            .navigationTitle("Hotel")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel", role: .cancel) { self.dismiss() }
                }
            }
        }
    }
}
