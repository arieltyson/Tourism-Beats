import Foundation

// MARK: - TravelCostReference

/// The bundled figures trip budgets are estimated from: how expensive each
/// country is, and roughly what a US dollar buys in other currencies.
///
/// Both are approximate and offline by design. They suggest a starting
/// budget and the kind of hotel it affords; travellers set the real numbers.
struct TravelCostReference: Sendable {
    /// Each country's cost band, by ISO country code.
    let costLevels: [String: CountryCostLevel]
    /// Units of each currency a US dollar buys, by ISO currency code.
    let dollarRates: [String: Double]

    static let shared = TravelCostReference(bundle: .main)

    init(costLevels: [String: CountryCostLevel], dollarRates: [String: Double]) {
        self.costLevels = costLevels
        self.dollarRates = dollarRates
    }

    /// Loads the bundled figures, or none where they're missing, in which
    /// case every country counts as moderate and budgets are kept in dollars.
    init(bundle: Bundle) {
        self.init(
            costLevels: Self.load("travel_cost_levels.json", from: bundle) ?? [:],
            dollarRates: Self.load("usd_exchange_rates.json", from: bundle) ?? [:]
        )
    }

    /// A country's band; countries without one count as moderate.
    func costLevel(forCountryCode code: String) -> CountryCostLevel {
        self.costLevels[code.uppercased()] ?? .moderate
    }

    /// Units of `currencyCode` a US dollar buys, if the currency is known.
    func dollarRate(for currencyCode: String) -> Double? {
        currencyCode.uppercased() == "USD" ? 1 : self.dollarRates[currencyCode.uppercased()]
    }

    private static func load<Value: Decodable>(_ filename: String, from bundle: Bundle) -> Value? {
        guard let url = bundle.url(forResource: filename, withExtension: nil),
              let data = try? Data(contentsOf: url)
        else { return nil }
        return try? JSONDecoder().decode(Value.self, from: data)
    }
}
