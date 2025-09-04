import SwiftUI

// MARK: - SearchableCountryPicker

struct SearchableCountryPicker: View {
    @Binding var selectedCode: String
    @State private var searchText = ""
    @Environment(\.dismiss) private var dismiss

    private let allCountries: [CountryModel] =
        (try? DataService().loadCountries()) ?? []

    private var groupedCountries: [String: [CountryModel]] {
        let filtered: [CountryModel]

        if self.searchText.isEmpty {
            filtered = self.allCountries
        } else {
            let lowercasedSearchText = self.searchText.lowercased()
            filtered = self.allCountries.filter { country in
                let nameWords = country.name.split(separator: " ")
                let nameMatches = nameWords.contains {
                    $0.lowercased().hasPrefix(lowercasedSearchText)
                }
                let codeMatches = country.code.localizedCaseInsensitiveContains(
                    self.searchText
                )
                return nameMatches || codeMatches
            }
        }

        return Dictionary(grouping: filtered) { country in
            String(country.name.prefix(1)).uppercased()
        }
    }

    private var sectionLetters: [String] {
        self.groupedCountries.keys.sorted()
    }

    var body: some View {
        NavigationStack {
            List {
                ForEach(self.sectionLetters, id: \.self) { letter in
                    Section(header: SectionHeader(letter: letter)) {
                        ForEach(self.groupedCountries[letter] ?? [], id: \.id) {
                            country in
                            CountryRow(
                                country: country,
                                selectedCode: self.$selectedCode
                            )
                            .contentShape(Rectangle())
                            .onTapGesture {
                                self.selectedCode = country.code
                                self.dismiss()
                            }
                        }
                    }
                }
            }
            .overlay(alignment: .trailing) {
                if self.searchText.isEmpty {
                    SectionIndexTitles(letters: self.sectionLetters)
                }
            }
            .searchable(text: self.$searchText, placement: .navigationBarDrawer)
            .navigationTitle("Select Country")
            .navigationBarTitleDisplayMode(.inline)
            .listStyle(.plain)
        }
        .presentationDetents([.medium, .large])
    }
}

// MARK: - SectionHeader

private struct SectionHeader: View {
    let letter: String

    var body: some View {
        Text(self.letter)
            .font(.system(.headline, design: .rounded))
            .foregroundColor(.accentColor)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.vertical, 8)
            .background(Color(.systemBackground))
    }
}

// MARK: - CountryRow

private struct CountryRow: View {
    let country: CountryModel
    @Binding var selectedCode: String

    var body: some View {
        HStack {
            Text("\(self.country.flag) \(self.country.name)")
                .font(.callout)

            Spacer()

            if self.selectedCode == self.country.code {
                Image(systemName: "checkmark")
                    .foregroundColor(.accentColor)
            }
        }
        .contentShape(Rectangle())
    }
}

// MARK: - SectionIndexTitles

private struct SectionIndexTitles: View {
    let letters: [String]
    @State private var selectedLetter: String?

    var body: some View {
        VStack(spacing: 2) {
            ForEach(self.letters, id: \.self) { letter in
                Text(letter)
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(
                        self.selectedLetter == letter ? .accentColor : .secondary
                    )
                    .frame(width: 20, height: 20)
                    .background(
                        GeometryReader { proxy in
                            Color.clear.onAppear {
                                let frame = proxy.frame(
                                    in: .named("SectionIndex")
                                )
                                if frame.midY > 0,
                                   frame.midY < UIScreen.main.bounds.height
                                {
                                    self.selectedLetter = letter
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
