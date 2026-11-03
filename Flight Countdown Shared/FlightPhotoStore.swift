import CoreGraphics
import Foundation
import ImageIO

/// Card photos, stored beside the flights in the app group so the widget can
/// draw them. Only the app writes; the widget reads.
actor FlightPhotoStore: FlightPhotoStoring {
    private let directory: URL?

    init(directory: URL? = FileManager.default.containerURL(
        forSecurityApplicationGroupIdentifier: FlightCountdownConfiguration.appGroup
    )?.appending(path: "FlightPhotos", directoryHint: .isDirectory)) {
        self.directory = directory
    }

    func image(for id: UUID, maximumPixelSize: Int) -> CGImage? {
        guard let url = url(for: id), let source = CGImageSourceCreateWithURL(url as CFURL, nil) else { return nil }
        let options: [CFString: Any] = [
            kCGImageSourceCreateThumbnailFromImageAlways: true,
            kCGImageSourceCreateThumbnailWithTransform: true,
            kCGImageSourceShouldCacheImmediately: true,
            kCGImageSourceThumbnailMaxPixelSize: maximumPixelSize,
        ]
        return CGImageSourceCreateThumbnailAtIndex(source, 0, options as CFDictionary)
    }

    func save(_ data: Data, for id: UUID) throws {
        guard let directory, let url = url(for: id) else { throw FlightCountdownStorageError.unavailable }
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        try data.write(to: url, options: [.atomic, .completeFileProtectionUntilFirstUserAuthentication])
    }

    func remove(for id: UUID) throws {
        guard let url = url(for: id) else { throw FlightCountdownStorageError.unavailable }
        guard FileManager.default.fileExists(atPath: url.path()) else { return }
        try FileManager.default.removeItem(at: url)
    }

    private func url(for id: UUID) -> URL? {
        directory?.appending(path: "\(id.uuidString).jpg")
    }
}
