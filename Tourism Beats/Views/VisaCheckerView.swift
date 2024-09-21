//
//  VisaCheckerView.swift
//  Tourism Beats
//
//  Created by Ariel Tyson on 20/9/24.
//

import SwiftUI

struct VisaCheckerView: View {
    @ObservedObject var viewModel: VisaCheckerViewModel

    var body: some View {
        VStack(alignment: .leading) {
            Text("Visa Free Travel Checker")
                .font(.headline)
                .padding(.bottom, 5)

            TextField("Select Country", text: $viewModel.searchText)
                .padding(10)
                .background(Color(.systemGray6))
                .cornerRadius(8)

            if !viewModel.suggestedCountries.isEmpty {
                List(viewModel.suggestedCountries) { country in
                    Button(action: {
                        viewModel.selectCountry(country)
                    }) {
                        Text(country.name)
                    }
                }
                .frame(maxHeight: 150)
            }

            if viewModel.isLoading {
                ProgressView()
                    .padding(.top, 10)
            } else if let visaFreeResult = viewModel.visaFreeResult {
                Text(visaFreeResult)
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundColor(visaFreeResult == "YES" ? .green : .red)
                    .padding(.top, 10)
            }
        }
        .padding()
    }
}
