import Foundation

protocol Currency: Equatable, Hashable {
    var code: String { get }
    var symbolTextRepresentation: String? { get }
    var name: String { get }
    var value: Int64 { get }
    var decimal: Double { get }
    var fractionalDegree: Int { get }
    var string: String { get }
    var stringWithCurrency: String { get }
    init?(string: String)
    init(value: Int64)
    
    // MARK: - Methods
    func asUICurrency() -> CurrencyUI
    func stringWithCurrency(
        fractionDigits: Int,
        useGroupingSeparator: Bool,
        roundingMode: NumberFormatter.RoundingMode
    ) -> String
    func string(
        fractionDigits: Int,
        useGroupingSeparator: Bool,
        roundingMode: NumberFormatter.RoundingMode
    ) -> String
    func abbreviateAmount(fractionDigits: Int) -> String
    func abbreviateAmountWithCurrency(fractionDigits: Int) -> String
    
    func floored() -> Self
}

// MARK: - Helpers

extension Currency {
    static func == (lhs: Self, rhs: Self) -> Bool {
        return lhs.code == rhs.code && lhs.value == rhs.value
    }
    func asAnyCurrency() -> AnyCurrency {
        return AnyCurrency(self)
    }
}

// MARK: - AnyCurrency

struct AnyCurrency: Currency {
    let currency: any Currency
    
    var code: String { currency.code }
    
    var fractionalDegree: Int { currency.fractionalDegree }
    var symbolTextRepresentation: String? { currency.symbolTextRepresentation }
    var name: String { currency.name }
    var value: Int64 { currency.value }
    
    var decimal: Double { currency.decimal }
    var string: String { currency.string }
    
    var stringWithCurrency: String { currency.stringWithCurrency }
    init(_ currency: any Currency) {
        self.currency = currency
    }
    init(value: Int64) {
        fatalError()
    }
    init?(string: String) {
        fatalError()
    }
    func abbreviateAmount(fractionDigits: Int = 2) -> String {
        currency.abbreviateAmount(fractionDigits: fractionDigits)
    }
    
    func abbreviateAmountWithCurrency(fractionDigits: Int = 2) -> String {
        currency.abbreviateAmountWithCurrency(fractionDigits: fractionDigits)
    }
    
    func hash(into hasher: inout Hasher) {
        currency.hash(into: &hasher)
    }
    
    func asUICurrency() -> CurrencyUI {
        currency.asUICurrency()
    }
    func stringWithCurrency(
        fractionDigits: Int,
        useGroupingSeparator: Bool,
        roundingMode: NumberFormatter.RoundingMode
    ) -> String {
        currency.stringWithCurrency(
            fractionDigits: fractionDigits,
            useGroupingSeparator: useGroupingSeparator,
            roundingMode: roundingMode
        )
    }
    func string(
        fractionDigits: Int,
        useGroupingSeparator: Bool,
        roundingMode: NumberFormatter.RoundingMode
    ) -> String  {
        currency.string(
            fractionDigits: fractionDigits,
            useGroupingSeparator: useGroupingSeparator,
            roundingMode: roundingMode
        )
    }
    
    func floored() -> AnyCurrency {
        return currency.floored().asAnyCurrency()
    }
}

// MARK: - String Extensions

extension String {
    func toLong(fractionalDegree: Int) -> Int64? {
        let decimalValue = NSDecimalNumber(string: self)
        guard decimalValue != NSDecimalNumber.notANumber else {
            return nil
        }
        let adjustedValue = decimalValue.multiplying(byPowerOf10: Int16(fractionalDegree))
        return Int64(exactly: adjustedValue)
    }
    func toLong() -> Int64? {
        Int64(exactly: NSDecimalNumber(string: self))
    }
    
    func replacingNonDigitAndDotSymbols() -> String {
        return self.replacingOccurrences(of: "[^0-9.]", with: "", options: .regularExpression)
    }
}

// MARK: - NSDecimalNumberHandler

extension NSDecimalNumberHandler {
    static let roundDown = NSDecimalNumberHandler(
        roundingMode: .down,
        scale: 0,
        raiseOnExactness: false,
        raiseOnOverflow: false,
        raiseOnUnderflow: false,
        raiseOnDivideByZero: false
    )
    
    static func handler(scale: Int16) -> NSDecimalNumberHandler {
        return NSDecimalNumberHandler(
            roundingMode: .plain,
            scale: scale,
            raiseOnExactness: false,
            raiseOnOverflow: false,
            raiseOnUnderflow: false,
            raiseOnDivideByZero: false
        )
    }
}

