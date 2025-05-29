import SwiftUI

struct SearchableCountryPicker: View {
    @Binding var selectedCode: String
    @State private var searchText = ""
    @Environment(\.dismiss) private var dismiss

    private var groupedCountries: [String: [CountryModel]] {
        let countries = CountryData.allCountries
        let filtered: [CountryModel]

        if searchText.isEmpty {
            filtered = countries
        } else {
            let lowercasedSearchText = searchText.lowercased()
            filtered = countries.filter { country in
                let nameWords = country.name.split(separator: " ")
                let nameMatches = nameWords.contains {
                    $0.lowercased().hasPrefix(lowercasedSearchText)
                }
                let codeMatches = country.code.localizedCaseInsensitiveContains(
                    searchText
                )
                return nameMatches || codeMatches
            }
        }

        return Dictionary(grouping: filtered) { country in
            String(country.name.prefix(1)).uppercased()
        }
    }

    private var sectionLetters: [String] {
        groupedCountries.keys.sorted()
    }

    var body: some View {
        NavigationStack {
            List {
                ForEach(sectionLetters, id: \.self) { letter in
                    Section(header: SectionHeader(letter: letter)) {
                        ForEach(groupedCountries[letter] ?? [], id: \.id) {
                            country in
                            CountryRow(
                                country: country,
                                selectedCode: $selectedCode
                            )
                            .contentShape(Rectangle())
                            .onTapGesture {
                                selectedCode = country.code
                                dismiss()
                            }
                        }
                    }
                }
            }
            .overlay(alignment: .trailing) {
                if searchText.isEmpty {
                    SectionIndexTitles(letters: sectionLetters)
                }
            }
            .searchable(text: $searchText, placement: .navigationBarDrawer)
            .navigationTitle("Select Country")
            .navigationBarTitleDisplayMode(.inline)
            .listStyle(.plain)
        }
        .presentationDetents([.medium, .large])
    }
}

// MARK: - Subcomponents
private struct SectionHeader: View {
    let letter: String

    var body: some View {
        Text(letter)
            .font(.system(.headline, design: .rounded))
            .foregroundColor(.accentColor)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.vertical, 8)
            .background(Color(.systemBackground))
    }
}

private struct CountryRow: View {
    let country: CountryModel
    @Binding var selectedCode: String

    var body: some View {
        HStack {
            Text("\(country.flag) \(country.name)")
                .font(.callout)

            Spacer()

            if selectedCode == country.code {
                Image(systemName: "checkmark")
                    .foregroundColor(.accentColor)
            }
        }
        .contentShape(Rectangle())
    }
}

private struct SectionIndexTitles: View {
    let letters: [String]
    @State private var selectedLetter: String?

    var body: some View {
        VStack(spacing: 2) {
            ForEach(letters, id: \.self) { letter in
                Text(letter)
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(
                        selectedLetter == letter ? .accentColor : .secondary
                    )
                    .frame(width: 20, height: 20)
                    .background(
                        GeometryReader { proxy in
                            Color.clear.onAppear {
                                let frame = proxy.frame(
                                    in: .named("SectionIndex")
                                )
                                if frame.midY > 0
                                    && frame.midY < UIScreen.main.bounds.height
                                {
                                    selectedLetter = letter
                                }
                            }
                        }
                    )
            }
        }
        .coordinateSpace(name: "SectionIndex")
        .padding(.trailing, 4)
    }
}
