// SearchableCountryPicker.swift
// Tourism Beats
//
// A searchable country list presented in a sheet,
// grouped alphabetically with section index titles.

import SwiftUI

// MARK: - SearchableCountryPicker

struct SearchableCountryPicker: View {
    @Binding var selectedCode: String
    @State private var searchText = ""
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @Environment(\.dismiss) private var dismiss

    private let allCountries: [CountryModel] =
        (try? DataService().loadCountries()) ?? []

    private var groupedCountries: [String: [CountryModel]] {
        let filtered: [CountryModel] = if self.searchText.isEmpty {
            self.allCountries
        } else {
            self.allCountries.filter { country in
                country.name.localizedStandardContains(self.searchText)
                    || country.code.localizedStandardContains(self.searchText)
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
                    Section(header: PickerSectionHeader(letter: letter)) {
                        ForEach(self.groupedCountries[letter] ?? [], id: \.id) { country in
                            Button {
                                self.selectedCode = country.code
                                self.dismiss()
                            } label: {
                                CountryRow(
                                    country: country,
                                    isSelected: self.selectedCode == country.code
                                )
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
            }
            .overlay(alignment: .trailing) {
                if self.searchText.isEmpty, !self.dynamicTypeSize.isAccessibilitySize {
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

// MARK: - PickerSectionHeader

private struct PickerSectionHeader: View {
    let letter: String

    var body: some View {
        Text(self.letter)
            .font(.system(.headline, design: .rounded))
            .foregroundStyle(.tint)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.vertical, SpacingTokens.xSmall)
    }
}

// MARK: - CountryRow

private struct CountryRow: View {
    let country: CountryModel
    let isSelected: Bool

    var body: some View {
        HStack {
            Text("\(self.country.flag) \(self.country.name)")
                .font(.callout)
                .foregroundStyle(.primary)

            Spacer()

            if self.isSelected {
                Image(systemName: "checkmark")
                    .foregroundStyle(.tint)
            }
        }
        .contentShape(.rect)
    }
}

// MARK: - SectionIndexTitles

private struct SectionIndexTitles: View {
    let letters: [String]

    var body: some View {
        VStack(spacing: 2) {
            ForEach(self.letters, id: \.self) { letter in
                Text(letter)
                    .font(TypographyTokens.footnote.bold())
                    .foregroundStyle(.secondary)
                    .frame(width: 16, height: 14)
            }
        }
        .padding(.trailing, SpacingTokens.xxSmall)
    }
}
