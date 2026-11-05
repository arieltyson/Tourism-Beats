import CoreGraphics
import Foundation
import Synchronization

/// A photo reduced to a small grid of colours, so a card can tell how
/// bright the photo is behind each line of text, and the photo's own
/// colour, deepened, to shade it with.
struct FlightPhotoTone: Sendable {
    /// Rows from the top of the photo, each from its leading edge.
    private let cells: [FlightRGB]
    private let side: Int
    /// The photo's average colour, deepened to sit behind white text.
    let shade: FlightRGB

    init(image: CGImage, side: Int = FlightCountdownStyle.toneGridSide) {
        self.side = side
        let cells = Self.cells(of: image, side: side) ?? Array(repeating: .white, count: side * side)
        self.cells = cells
        self.shade = Self.shade(for: cells)
    }

    /// The brightest cell overlapping `region`, in the photo's unit
    /// coordinates from the top leading corner. A single bright patch is
    /// enough to lose text, so the brightest counts, not the average.
    func brightest(in region: CGRect) -> FlightRGB {
        let unit = region.intersection(CGRect(x: 0, y: 0, width: 1, height: 1))
        guard !unit.isNull, !unit.isEmpty else { return .white }
        let scale = Double(side)
        let columns = Int((unit.minX * scale).rounded(.down))...min(Int((unit.maxX * scale).rounded(.up)) - 1, side - 1)
        let rows = Int((unit.minY * scale).rounded(.down))...min(Int((unit.maxY * scale).rounded(.up)) - 1, side - 1)
        var brightest = FlightRGB.black
        var brightestLuminance = -1.0
        for row in rows {
            for column in columns {
                let cell = cells[row * side + column]
                let luminance = FlightPhotoContrast.luminance(of: cell)
                if luminance > brightestLuminance { (brightest, brightestLuminance) = (cell, luminance) }
            }
        }
        return brightest
    }

    // MARK: Cache

    private static let cache = Mutex<[UUID: FlightPhotoTone]>([:])

    /// The tone of the photo stored as `id`. A stored photo's pixels never
    /// change, only its framing, so each is measured once per process.
    static func cached(for id: UUID, image: CGImage) -> Self {
        if let tone = cache.withLock({ $0[id] }) { return tone }
        let tone = Self(image: image)
        cache.withLock { $0[id] = tone }
        return tone
    }

    // MARK: Measuring

    private static func cells(of image: CGImage, side: Int) -> [FlightRGB]? {
        guard let space = CGColorSpace(name: CGColorSpace.sRGB),
              let context = CGContext(
                  data: nil, width: side, height: side, bitsPerComponent: 8, bytesPerRow: side * 4,
                  space: space, bitmapInfo: CGImageAlphaInfo.noneSkipLast.rawValue
              )
        else { return nil }
        // Averaging into the grid is what's wanted, so let it filter.
        context.interpolationQuality = .medium
        context.draw(image, in: CGRect(x: 0, y: 0, width: side, height: side))
        guard let data = context.data else { return nil }
        // A bitmap context's memory runs from the top row down.
        let bytes = UnsafeBufferPointer(start: data.assumingMemoryBound(to: UInt8.self), count: side * side * 4)
        return stride(from: 0, to: bytes.count, by: 4).map { offset in
            FlightRGB(
                red: Double(bytes[offset]) / 255,
                green: Double(bytes[offset + 1]) / 255,
                blue: Double(bytes[offset + 2]) / 255
            )
        }
    }

    /// The average hue, kept gently saturated and brought down to a deep
    /// tone, so the scrim reads as the photo's own shadow rather than grey.
    private static func shade(for cells: [FlightRGB]) -> FlightRGB {
        let count = Double(max(cells.count, 1))
        let average = FlightRGB(
            red: cells.map(\.red).reduce(0, +) / count,
            green: cells.map(\.green).reduce(0, +) / count,
            blue: cells.map(\.blue).reduce(0, +) / count
        )
        let peak = max(average.red, average.green, average.blue)
        let floor = min(average.red, average.green, average.blue)
        guard peak > 0 else { return .black }
        let saturation = min((peak - floor) / peak, FlightCountdownStyle.shadeMaximumSaturation)
        let brightness = FlightCountdownStyle.shadeBrightness
        // Rebuild the colour with the same hue at the chosen saturation and
        // brightness: each component keeps its place between floor and peak.
        func component(_ c: Double) -> Double {
            let position = peak > floor ? (c - floor) / (peak - floor) : 1
            return brightness * (1 - saturation * (1 - position))
        }
        return FlightRGB(red: component(average.red), green: component(average.green), blue: component(average.blue))
    }
}
