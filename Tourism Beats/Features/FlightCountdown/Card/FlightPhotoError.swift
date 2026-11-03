import Foundation

enum FlightPhotoError: LocalizedError {
    case unreadable

    var errorDescription: String? {
        String(localized: "This photo couldn’t be opened. Try another one.")
    }
}
