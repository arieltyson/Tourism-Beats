import Foundation

extension Duration {
    /// The duration in seconds, for APIs such as `URLRequest` that still take
    /// a `TimeInterval`.
    var timeInterval: TimeInterval {
        let (seconds, attoseconds) = self.components
        return TimeInterval(seconds) + TimeInterval(attoseconds) / 1e18
    }
}
