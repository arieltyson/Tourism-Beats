import SwiftUI

struct VisaView: View {
    @StateObject var viewModel: VisaViewModel
    private let allCountries: [CountryModel] =
        (try? DataService().loadCountries()) ?? []
    @State private var showingCountryPicker = false

    private var currentCountry: CountryModel? {
        allCountries.first { $0.code == viewModel.passportCode }
    }

    var body: some View {
        NeumorphicCard {
            VStack(alignment: .leading, spacing: 16) {
                Text("Travel Visa Advisory")
                    .font(.title2.italic())
                    .foregroundColor(.blue)

                HStack(alignment: .top) {
                    Button {
                        showingCountryPicker = true
                    } label: {
                        HStack {
                            if let country = currentCountry {
                                Text("\(country.flag) \(country.name)")
                                    .foregroundColor(.primary)
                            } else {
                                Text("Select Country")
                            }
                            Spacer()
                            Image(systemName: "chevron.down")
                                .foregroundColor(.accentColor)
                        }
                    }
                    .padding(.vertical, 8)
                    .padding(.horizontal, 12)
                    .background(
                        Capsule()
                            .fill(Color.accentColor.opacity(0.2))
                            .shadow(
                                color: Color.accentColor.opacity(0.3),
                                radius: 4,
                                x: 2,
                                y: 2
                            )
                    )
                    .sheet(isPresented: $showingCountryPicker) {
                        SearchableCountryPicker(
                            selectedCode: $viewModel.passportCode
                        )
                    }
                    .onChange(of: viewModel.passportCode) {
                        viewModel.updatePassport(to: $0)
                    }

                    Group {
                        if viewModel.isLoading {
                            ProgressView()
                        } else if viewModel.errorMessage != nil {
                            Text("Error")
                                .foregroundColor(.red)
                        } else if viewModel.requirement != nil {
                            Text(viewModel.summaryText)
                                .font(.subheadline)
                                .fontWeight(.semibold)
                                .foregroundColor(viewModel.requirementColor)
                        } else {
                            Text("No info")
                                .foregroundColor(.gray)
                        }
                    }
                    .fixedSize(horizontal: false, vertical: true)
                    .multilineTextAlignment(.trailing)
                    .frame(maxWidth: .infinity, alignment: .trailing)
                }
            }
        }
        .padding()
    }
}
