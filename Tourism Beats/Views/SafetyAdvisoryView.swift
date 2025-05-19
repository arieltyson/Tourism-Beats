import SwiftUI

struct SafetyAdvisoryView: View {
    @StateObject var viewModel: SafetyAdvisoryViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Travel Safety Advisory")
                .font(.largeTitle)
                .italic()
                .foregroundColor(.blue)

            if viewModel.isLoading {
                ProgressView()
                    .padding(.top, 10)

            } else if let errorMessage = viewModel.errorMessage {
                Text("Error: \(errorMessage)")
                    .foregroundColor(.red)

            } else if let safetyData = viewModel.safetyData {
                Text("Country: \(safetyData.countryName)")
                    .font(.title2)
                    .bold()

                HStack {
                    Text("Risk Level: \(viewModel.riskLevelScoreText ?? "")")
                        .font(.title3)

                    Spacer()

                    Text(viewModel.riskLevelText ?? "")
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundColor(viewModel.riskLevelColor)
                }

            } else {
                Text("No advisory information available.")
            }
        }
        .padding()
        .background(Color(.systemBackground).opacity(0.8))
        .cornerRadius(10)
        .padding()
    }
}
