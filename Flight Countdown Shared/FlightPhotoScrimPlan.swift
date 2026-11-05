import CoreGraphics

/// How dark a card's scrim is down its height, worked out from the photo
/// behind it so every line of text reaches its contrast target, and no
/// darker than that.
///
/// The card is read in bands: the destination and date at the top, the
/// countdown in the middle, the route at the bottom. Each band is shaded
/// just enough for white secondary text over the brightest part of the
/// photo within it, as framed in this frame.
enum FlightPhotoScrimPlan {
    struct Stop: Equatable {
        let location: Double
        let opacity: Double
    }

    static func stops(
        for tone: FlightPhotoTone,
        imageSize: CGSize,
        framing: FlightPhotoFraming,
        frameSize: CGSize,
        target: Double
    ) -> [Stop] {
        let bands = FlightCountdownStyle.scrimBands
        let opacities = bands.map { band in
            max(band.minimumOpacity, requiredOpacity(
                for: band.span, tone: tone, imageSize: imageSize, framing: framing, frameSize: frameSize, target: target
            ))
        }
        return stops(bands: bands, opacities: opacities)
    }

    /// The opacity a band needs over the photo as framed.
    private static func requiredOpacity(
        for span: ClosedRange<Double>,
        tone: FlightPhotoTone,
        imageSize: CGSize,
        framing: FlightPhotoFraming,
        frameSize: CGSize,
        target: Double
    ) -> Double {
        guard frameSize.width > 0, frameSize.height > 0 else { return 0 }
        // Where the band falls on the photo, in the photo's unit coordinates.
        let drawn = framing.rect(for: imageSize, in: frameSize)
        let region = CGRect(
            x: -drawn.minX / drawn.width,
            y: (span.lowerBound * frameSize.height - drawn.minY) / drawn.height,
            width: frameSize.width / drawn.width,
            height: (span.upperBound - span.lowerBound) * frameSize.height / drawn.height
        )
        // The photo is drawn with a contrast lift; measure what's on screen.
        let background = FlightPhotoContrast.adjusted(
            tone.brightest(in: region), contrast: FlightCountdownStyle.photoContrast
        )
        return FlightPhotoContrast.scrimOpacity(
            over: background,
            scrim: tone.shade,
            textOpacity: FlightCountdownStyle.secondaryOpacity,
            target: target,
            maximum: FlightCountdownStyle.maximumScrimOpacity
        )
    }

    /// Joins the bands with a short feather. Each feather sits in the
    /// lighter band, so text at a band's edge keeps its band's full shade.
    private static func stops(bands: [FlightScrimBand], opacities: [Double]) -> [Stop] {
        guard let first = opacities.first, let last = opacities.last else { return [] }
        let feather = FlightCountdownStyle.scrimFeather
        var stops = [Stop(location: 0, opacity: first)]
        for index in bands.indices.dropLast() {
            let edge = bands[index].span.upperBound
            let (above, below) = (opacities[index], opacities[index + 1])
            if above >= below {
                stops += [Stop(location: edge, opacity: above), Stop(location: edge + feather, opacity: below)]
            } else {
                stops += [Stop(location: edge - feather, opacity: above), Stop(location: edge, opacity: below)]
            }
        }
        stops.append(Stop(location: 1, opacity: last))
        return stops
    }
}
