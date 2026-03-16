import Foundation
import ImageIO
import UniformTypeIdentifiers

// MARK: - RestaurantMealPhotoStoreError

enum RestaurantMealPhotoStoreError: Error {
    case failedToDecodeImage
    case failedToEncodeImage
}

// MARK: - RestaurantMealPhotoStore

actor RestaurantMealPhotoStore {
    static let shared = RestaurantMealPhotoStore()

    nonisolated static func fileURL(for relativePath: String) -> URL {
        self.baseDirectory.appending(path: relativePath)
    }

    private nonisolated static var baseDirectory: URL {
        URL.applicationSupportDirectory.appending(path: "RestaurantMealPhotos", directoryHint: .isDirectory)
    }

    func persistPhotoData(
        _ data: Data,
        restaurantIdentifier: UUID,
        photoIdentifier: UUID
    ) throws -> String {
        let optimizedData = try self.optimizedJPEGData(from: data)
        let relativePath = "\(restaurantIdentifier.uuidString)/\(photoIdentifier.uuidString).jpg"
        let fileURL = Self.fileURL(for: relativePath)

        try FileManager.default.createDirectory(
            at: fileURL.deletingLastPathComponent(),
            withIntermediateDirectories: true,
            attributes: nil
        )

        try optimizedData.write(to: fileURL, options: .atomic)
        return relativePath
    }

    func deleteFiles(at relativePaths: [String]) throws {
        for relativePath in relativePaths where !relativePath.isEmpty {
            let fileURL = Self.fileURL(for: relativePath)

            if FileManager.default.fileExists(atPath: fileURL.path) {
                try FileManager.default.removeItem(at: fileURL)
            }
        }
    }

    private func optimizedJPEGData(from data: Data) throws -> Data {
        guard let imageSource = CGImageSourceCreateWithData(data as CFData, nil) else {
            throw RestaurantMealPhotoStoreError.failedToDecodeImage
        }

        let options: [CFString: Any] = [
            kCGImageSourceCreateThumbnailFromImageAlways: true,
            kCGImageSourceCreateThumbnailWithTransform: true,
            kCGImageSourceShouldCacheImmediately: true,
            kCGImageSourceThumbnailMaxPixelSize: 1_600
        ]

        guard let image = CGImageSourceCreateThumbnailAtIndex(
            imageSource,
            0,
            options as CFDictionary
        ) else {
            throw RestaurantMealPhotoStoreError.failedToDecodeImage
        }

        let outputData = NSMutableData()
        guard let destination = CGImageDestinationCreateWithData(
            outputData,
            UTType.jpeg.identifier as CFString,
            1,
            nil
        ) else {
            throw RestaurantMealPhotoStoreError.failedToEncodeImage
        }

        let properties: [CFString: Any] = [
            kCGImageDestinationLossyCompressionQuality: 0.82
        ]
        CGImageDestinationAddImage(destination, image, properties as CFDictionary)

        guard CGImageDestinationFinalize(destination) else {
            throw RestaurantMealPhotoStoreError.failedToEncodeImage
        }

        return outputData as Data
    }
}
