/// What saving a flight does to its card photo. Choosing a designed
/// background instead of a photo removes the photo.
enum FlightPhotoChange: Sendable {
    case unchanged
    case replace(FlightPhoto)
}
