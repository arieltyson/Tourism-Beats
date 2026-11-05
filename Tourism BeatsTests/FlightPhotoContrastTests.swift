import CoreGraphics
import SwiftUI
import Testing
@testable import Tourism_Beats

struct FlightPhotoContrastTests {
    private typealias Contrast = FlightPhotoContrast

    /// A photo whose top `brightTop` of its height is `top` and the rest `bottom`.
    private func photo(top: FlightRGB, bottom: FlightRGB, brightTop: Double = 0.5, side: Int = 64) throws -> CGImage {
        let space = try #require(CGColorSpace(name: CGColorSpace.sRGB))
        let context = try #require(CGContext(
            data: nil, width: side, height: side, bitsPerComponent: 8, bytesPerRow: side * 4,
            space: space, bitmapInfo: CGImageAlphaInfo.noneSkipLast.rawValue
        ))
        let split = Double(side) * (1 - brightTop)
        context.setFillColor(red: bottom.red, green: bottom.green, blue: bottom.blue, alpha: 1)
        context.fill(CGRect(x: 0, y: 0, width: Double(side), height: split))
        context.setFillColor(red: top.red, green: top.green, blue: top.blue, alpha: 1)
        context.fill(CGRect(x: 0, y: split, width: Double(side), height: Double(side) - split))
        return try #require(context.makeImage())
    }

    /// The contrast white secondary text actually gets over `background`
    /// shaded by `stop`.
    private func textContrast(over background: FlightRGB, tone: FlightPhotoTone, opacity: Double) -> Double {
        let lifted = Contrast.adjusted(background, contrast: FlightCountdownStyle.photoContrast)
        let shaded = Contrast.blend(tone.shade, over: lifted, opacity: opacity)
        let text = Contrast.blend(.white, over: shaded, opacity: FlightCountdownStyle.secondaryOpacity)
        return Contrast.ratio(text, shaded)
    }

    private func stops(for image: CGImage, target: Double = FlightCountdownStyle.textContrast) -> [FlightPhotoScrimPlan.Stop] {
        FlightPhotoScrimPlan.stops(
            for: FlightPhotoTone(image: image),
            imageSize: CGSize(width: image.width, height: image.height),
            framing: .centered,
            frameSize: CGSize(width: 340, height: 160),
            target: target
        )
    }

    /// The opacity in effect at `location`.
    private func opacity(at location: Double, in stops: [FlightPhotoScrimPlan.Stop]) -> Double {
        guard let next = stops.firstIndex(where: { $0.location >= location }) else { return stops.last?.opacity ?? 0 }
        guard next > 0 else { return stops[next].opacity }
        let (a, b) = (stops[next - 1], stops[next])
        return a.opacity + (b.opacity - a.opacity) * (location - a.location) / max(b.location - a.location, .ulpOfOne)
    }

    @Test func contrastMatchesWCAG() {
        #expect(abs(Contrast.ratio(.white, .black) - 21) < 0.001)
        #expect(Contrast.ratio(.white, .white) == 1)
        let grey = FlightRGB(red: 0.467, green: 0.467, blue: 0.467)
        #expect(abs(Contrast.ratio(.white, grey) - 4.5) < 0.05)
    }

    @Test func theGridReadsThePhotoTopDown() throws {
        let tone = FlightPhotoTone(image: try photo(top: .white, bottom: .black))
        #expect(tone.brightest(in: CGRect(x: 0, y: 0, width: 1, height: 0.4)) == .white)
        #expect(tone.brightest(in: CGRect(x: 0, y: 0.6, width: 1, height: 0.4)) == .black)
    }

    @Test(arguments: [
        (FlightRGB.white, FlightRGB.white),
        (FlightRGB(red: 0.9, green: 0.85, blue: 0.6), FlightRGB(red: 0.95, green: 0.95, blue: 1)),
        (FlightRGB(red: 0.5, green: 0.7, blue: 1), FlightRGB(red: 0.2, green: 0.6, blue: 0.3)),
    ])
    func everyBandReachesItsTargetOverBrightPhotos(top: FlightRGB, bottom: FlightRGB) throws {
        let image = try photo(top: top, bottom: bottom)
        let tone = FlightPhotoTone(image: image)
        let plan = stops(for: image)
        for band in FlightCountdownStyle.scrimBands {
            for location in stride(from: band.span.lowerBound, through: band.span.upperBound, by: 0.05) {
                let background = location < 0.5 ? top : bottom
                let contrast = textContrast(over: background, tone: tone, opacity: opacity(at: location, in: plan))
                #expect(contrast >= FlightCountdownStyle.textContrast - 0.01, "\(location): \(contrast)")
            }
        }
    }

    @Test func aDarkPhotoKeepsOnlyItsGentleFrame() throws {
        let plan = stops(for: try photo(top: .black, bottom: FlightRGB(red: 0.1, green: 0.1, blue: 0.15)))
        let bands = FlightCountdownStyle.scrimBands
        #expect(plan.first?.opacity == bands.first?.minimumOpacity)
        #expect(opacity(at: 0.6, in: plan) == bands[1].minimumOpacity)
        #expect(plan.last?.opacity == bands.last?.minimumOpacity)
    }

    @Test func onlyTheBrightPartIsShaded() throws {
        // A bright sky over a dark street: the top darkens, the middle doesn't.
        let plan = stops(for: try photo(top: .white, bottom: .black, brightTop: 0.35))
        #expect(opacity(at: 0.1, in: plan) > 0.5)
        #expect(opacity(at: 0.6, in: plan) == 0)
    }

    @Test func increasedContrastShadesMore() throws {
        let image = try photo(top: .white, bottom: .white)
        let standard = opacity(at: 0.6, in: stops(for: image))
        let increased = opacity(at: 0.6, in: stops(for: image, target: FlightCountdownStyle.increasedTextContrast))
        #expect(increased > standard)
    }

    @Test(arguments: FlightCardTheme.gradients)
    func designedBackgroundsKeepSecondaryTextLegible(theme: FlightCardTheme) throws {
        let sRGB = try #require(CGColorSpace(name: CGColorSpace.sRGB))
        for tone in theme.palette {
            let resolved = tone.resolve(in: EnvironmentValues()).cgColor
            let cgColor = try #require(resolved.converted(to: sRGB, intent: .defaultIntent, options: nil))
            let components = try #require(cgColor.components)
            let background = FlightRGB(red: components[0], green: components[1], blue: components[2])
            let text = Contrast.blend(.white, over: background, opacity: FlightCountdownStyle.secondaryOpacity)
            #expect(Contrast.ratio(text, background) >= FlightCountdownStyle.textContrast - 0.01)
        }
    }
}
