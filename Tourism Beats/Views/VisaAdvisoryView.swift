import SwiftUI

struct VisaAdvisoryView: View {
    @StateObject var viewModel: VisaAdvisoryViewModel
    private let allCountries = CountryData.allCountries

    var body: some View {
        NeumorphicCard {
            VStack(alignment: .leading, spacing: 16) {
                Text("Travel Visa Advisory")
                    .font(.title2.italic())
                    .foregroundColor(.blue)

                // Picker + requirement on one line
                HStack(alignment: .center) {
                    Picker("", selection: $viewModel.passportCode) {
                        ForEach(allCountries, id: \.code) { c in
                            Text("\(c.flag) \(c.name)").tag(c.code)
                        }
                    }
                    .pickerStyle(MenuPickerStyle())
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
                    .onChange(of: viewModel.passportCode) {
                        viewModel.updatePassport(to: $0)
                    }

                    Spacer()

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
                    .padding()
                }
            }
        }
        .padding()
    }
}
