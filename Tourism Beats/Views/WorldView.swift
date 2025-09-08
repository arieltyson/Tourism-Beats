import MapKit
import SwiftUI

struct WorldView: View {
    let onCitySelected: (CityModel) -> Void

    // Map state
    @State private var selectedCity: CityModel?
    @State private var showAlert = false
    @State private var region = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 54.5260, longitude: 15.2551),
        span: MKCoordinateSpan(latitudeDelta: 20, longitudeDelta: 20)
    )
    @State private var lastRegion: MKCoordinateRegion?
    @State private var alertTimeoutTask: Task<Void, Never>?

    // Search state
    @State private var showSearchOverlay = false

    // Selection source tracking
    private enum SelectionSource {
        case search
        case map
    }

    @State private var selectionSource: SelectionSource = .map

    private let cities: [CityModel]

    init(onCitySelected: @escaping (CityModel) -> Void) {
        self.onCitySelected = onCitySelected
        self.cities = (try? DataService().loadCities()) ?? []
    }

    var body: some View {
        ZStack {
            // Map view
            VStack(spacing: 0) {
                // Header with search button
                self.headerView

                MapView(
                    selectedCity: self.$selectedCity,
                    showAlert: self.$showAlert,
                    region: self.$region,
                    lastRegion: self.$lastRegion,
                    cities: self.cities,
                    onCitySelected: { _ in
                        // This callback is not used for map selections
                        // Map selections only show alert, navigation happens in alert
                    }
                )
                .edgesIgnoringSafeArea(.all)
            }

            // Search overlay
            if self.showSearchOverlay {
                CitySearchOverlay(
                    isPresented: self.$showSearchOverlay,
                    selectedCity: self.$selectedCity,
                    region: self.$region,
                    showAlert: self.$showAlert,
                    cities: self.cities,
                    onCitySelected: { city in
                        self.selectionSource = .search
                        // Direct navigation for search - no alert
                        self.onCitySelected(city)
                    }
                )
                .onChange(of: self.showSearchOverlay) { _, isPresented in
                    if !isPresented {
                        // Reset to map source when search is dismissed
                        self.selectionSource = .map
                    }
                }
                .transition(.asymmetric(
                    insertion: .opacity.combined(with: .scale(scale: 0.95)),
                    removal: .opacity.combined(with: .scale(scale: 0.95))
                ))
            }
        }
        .background(Color.black.ignoresSafeArea())
        .onAppear {
            // Reset state when returning to map view to ensure clean state
            self.selectedCity = nil
            self.showAlert = false
            self.lastRegion = nil
            self.selectionSource = .map
            self.alertTimeoutTask?.cancel()
        }
        .onDisappear {
            // Clean up state when leaving the view
            self.selectedCity = nil
            self.showAlert = false
            self.lastRegion = nil
            self.alertTimeoutTask?.cancel()
        }
        .onChange(of: self.showAlert) { _, newValue in
            if newValue {
                // Set a timeout to automatically dismiss the alert if it gets stuck
                self.alertTimeoutTask = Task {
                    try? await Task.sleep(nanoseconds: 10_000_000_000) // 10 seconds
                    if !Task.isCancelled {
                        await MainActor.run {
                            self.showAlert = false
                            self.selectedCity = nil
                            self.lastRegion = nil
                        }
                    }
                }
            } else {
                // Cancel timeout when alert is dismissed
                self.alertTimeoutTask?.cancel()
            }
        }
        .alert(isPresented: Binding(
            get: { self.showAlert && self.selectionSource == .map },
            set: { self.showAlert = $0 }
        )) {
            Alert(
                title: Text("Explore \(self.selectedCity?.name ?? "")?"),
                message: Text(
                    "Would you like to explore \(self.selectedCity?.name ?? ""), \(self.selectedCity?.country.name ?? "")?"
                ),
                primaryButton: .default(Text("Yes")) {
                    // Navigate to city view
                    if let city = selectedCity {
                        self.onCitySelected(city)
                    }
                    // Clear state immediately
                    self.selectedCity = nil
                    self.showAlert = false
                    self.lastRegion = nil
                },
                secondaryButton: .cancel {
                    // Restore region and clear state
                    self.region = self.lastRegion ?? self.region
                    self.lastRegion = nil
                    self.selectedCity = nil
                    self.showAlert = false
                }
            )
        }
    }

    // MARK: - Header View

    private var headerView: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("Select a City")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(.white)

                Text("Tap to explore or search")
                    .font(.subheadline)
                    .foregroundColor(.white.opacity(0.8))
            }

            Spacer()

            // Search button
            Button(action: {
                withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                    self.showSearchOverlay = true
                }
            }) {
                HStack(spacing: 8) {
                    Image(systemName: "magnifyingglass")
                        .font(.system(size: 16, weight: .medium))
                    Text("Search")
                        .font(.system(size: 16, weight: .medium))
                }
                .foregroundColor(.white)
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 20)
        .padding(.top, 10)
        .padding(.bottom, 16)
    }
}
