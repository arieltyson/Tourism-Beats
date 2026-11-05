import Foundation

/// Which of a card's photos fills it at a given moment.
///
/// The photos take turns in a shuffled order, reshuffled once every photo
/// has had its turn, so none is favoured and none shows twice in a row.
/// The order comes from the flight and the time alone, so the app and the
/// widget agree without storing anything, and the widget needs no button.
enum FlightPhotoRotation {
    /// The photo filling `flight`'s card at `date`.
    static func photo(from photos: [FlightCardImage], of flight: CountdownFlight, at date: Date) -> FlightCardImage? {
        photos.isEmpty ? nil : photos[index(count: photos.count, seed: flight.id, at: date)]
    }

    static func index(count: Int, seed: UUID, at date: Date) -> Int {
        guard count > 1 else { return 0 }
        let turn = Int((date.timeIntervalSinceReferenceDate / FlightCountdownStyle.photoInterval).rounded(.down))
        // Two photos can only alternate without repeating.
        guard count > 2 else { return turn & 1 }
        let round = Int((Double(turn) / Double(count)).rounded(.down))
        var order = shuffled(count, seed: seed, round: round)
        // A round never opens with the photo the one before it ended on.
        // Only the first two places move, so the previous round's last
        // photo is the same with or without its own swap.
        if order[0] == shuffled(count, seed: seed, round: round - 1)[count - 1] {
            order.swapAt(0, 1)
        }
        return order[turn - round * count]
    }

    /// A Fisher–Yates shuffle with its own generator, so the order can't
    /// change with the standard library's shuffling or between processes.
    private static func shuffled(_ count: Int, seed: UUID, round: Int) -> [Int] {
        var generator = SplitMix64(seed: seed, round: round)
        var order = Array(0..<count)
        for index in order.indices.dropLast().reversed() {
            order.swapAt(index, Int(generator.next() % UInt64(index + 1)))
        }
        return order
    }
}

/// A small, stable pseudo-random generator.
private struct SplitMix64 {
    private var state: UInt64

    init(seed: UUID, round: Int) {
        let bytes = withUnsafeBytes(of: seed.uuid) { Array($0) }
        let high = bytes[0..<8].reduce(UInt64(0)) { $0 << 8 | UInt64($1) }
        let low = bytes[8..<16].reduce(UInt64(0)) { $0 << 8 | UInt64($1) }
        state = high ^ low.rotated() ^ UInt64(bitPattern: Int64(round)) &* 0x9E37_79B9_7F4A_7C15
    }

    mutating func next() -> UInt64 {
        state &+= 0x9E37_79B9_7F4A_7C15
        var value = state
        value = (value ^ (value >> 30)) &* 0xBF58_476D_1CE4_E5B9
        value = (value ^ (value >> 27)) &* 0x94D0_49BB_1331_11EB
        return value ^ (value >> 31)
    }
}

private extension UInt64 {
    func rotated() -> UInt64 { self << 32 | self >> 32 }
}
