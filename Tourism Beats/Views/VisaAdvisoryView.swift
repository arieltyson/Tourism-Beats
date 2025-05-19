import SwiftUI

struct VisaAdvisoryView: View {
    @StateObject var viewModel: VisaAdvisoryViewModel
    private let allCountries = CountryData.allCountries

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Travel Visa Advisory")
                .font(.largeTitle)
                .italic()
                .foregroundColor(.blue)

            Picker("Passport", selection: $viewModel.passportCode) {
                ForEach(allCountries, id: \.code) { c in
                    Text("\(c.flag) \(c.name)").tag(c.code)
                }
            }
            .pickerStyle(MenuPickerStyle())
            .onChange(of: viewModel.passportCode) {
                viewModel.updatePassport(to: $0)
            }

            if viewModel.isLoading {
                ProgressView().padding(.top, 8)

            } else if let err = viewModel.errorMessage {
                Text("Error: \(err)").foregroundColor(.red)

            } else if viewModel.requirement != nil {
                Text("Destination: \(viewModel.destinationCode)")
                    .font(.title2)
                    .bold()

                Text(viewModel.summaryText)
                    .font(.title3)
                    .foregroundColor(.primary)

            } else {
                Text("No visa information available.")
            }
        }
        .padding()
        .background(Color(.systemBackground).opacity(0.8))
        .cornerRadius(10)
        .padding(.horizontal)
    }
}
