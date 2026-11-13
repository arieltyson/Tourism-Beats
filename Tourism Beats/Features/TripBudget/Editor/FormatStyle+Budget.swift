import Foundation

extension FormatStyle where Self == FloatingPointFormatStyle<Double>.Currency {
    /// A budget amount in whole units, such as "$1,850".
    static func budget(_ currencyCode: String) -> Self {
        .currency(code: currencyCode).precision(.fractionLength(0))
    }
}
