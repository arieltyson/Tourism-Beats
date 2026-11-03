import Foundation

enum FlightCountdownStorageError: LocalizedError {
    case unavailable

    var errorDescription: String? {
        "Flight storage is unavailable. Please try again."
    }
}
