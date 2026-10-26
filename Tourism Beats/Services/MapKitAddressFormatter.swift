import Foundation

// MARK: - MapKitAddressFormatter

/// Normalizes the short addresses MapKit returns for display.
///
/// Apple Maps can separate address components with " | " and leave empty or
/// doubled separators behind; every place shown in the app uses commas.
enum MapKitAddressFormatter {
    static func displayAddress(_ address: String?) -> String? {
        guard let address = address?.trimmingCharacters(in: .whitespacesAndNewlines),
              !address.isEmpty
        else {
            return nil
        }

        let cleaned = address
            .replacing(/\s*\|\s*/, with: ", ")
            .replacing(/,\s*,+/, with: ", ")
            .replacing(/\s{2,}/, with: " ")
            .trimmingCharacters(in: CharacterSet(charactersIn: ",|").union(.whitespacesAndNewlines))

        return cleaned.isEmpty ? nil : cleaned
    }
}
