import Foundation
import UIKit

struct Usd: Currency, Codable {
    struct Fractional {
        var degree: Int { Int(degreeInt16) }
        var precision: Double { pow(10.0, Double(degree)) }
        
        fileprivate let degreeInt16: Int16 = 2
    }
    
    // MARK: - Meta info
    var code: String { "USD" }
    var symbolTextRepresentation: String? { "$" }
    var name: String { "USD" }
    var decimal: Double { USD.remainder(dividingBy: 1) }
    
    // MARK: - String representation
    var string: String { string() }
    var stringWithCurrency: String { stringWithCurrency() }
    
    /// Internal value in cents (2 decimals)
    let value: Int64
    /// Fractional degree
    var fractionalDegree: Int { Usd.fractional.degree }
    
    static let zero = Usd(value: 0)
    static let one = Usd(usd: 1)
    
    static let fractional = Fractional()
    
    // MARK: - Init
    
    init(value: Int64) {
        self.value = value
    }
    
    init(usd: Double) {
        self.value = Int64(
            truncating: NSDecimalNumber(value: usd)
                .multiplying(by: NSDecimalNumber(value: Self.fractional.precision))
                .rounding(
                    accordingToBehavior: NSDecimalNumberHandler.handler(scale: Self.fractional.degreeInt16)
                )
        )
    }
    
    /// Make USD from string
    /// - Parameter string: USD string in format "$1.00" or "1.00"
    init?(string: String) {
        guard let longValue = string.replacingNonDigitAndDotSymbols().toLong(fractionalDegree: 2) else { return nil }
        self.value = longValue
    }
    
    func asUICurrency() -> CurrencyUI {
        CurrencyUI(self.asAnyCurrency())
    }
}

// MARK: - Comparable

extension Usd: Comparable {
    static func < (lhs: Usd, rhs: Usd) -> Bool {
        lhs.value < rhs.value
    }
}

// MARK: - Operators

extension Usd {
    static func / (lhs: Usd, rhs: Usd) -> Usd {
        Usd(value: lhs.value / rhs.value)
    }
    static func / (lhs: Usd, rhs: Double) -> Usd {
        Usd(value: Int64(Double(lhs.value) / rhs))
    }
    static func > (lhs: Usd, rhs: Usd) -> Bool {
        lhs.value > rhs.value
    }
    
    init?(centsString value: String) {
        guard let longValue = value.replacingNonDigitAndDotSymbols().toLong() else { return nil }
        self.value = longValue
    }
    
    init(cents: Int64) {
        self.value = cents
    }
    
    static func +(lhs: Usd, rhs: Usd) -> Usd {
        return Usd(value: lhs.value + rhs.value)
    }
    
    static func -(lhs: Usd, rhs: Usd) -> Usd {
        return Usd(value: lhs.value - rhs.value)
    }
    
    static func *(lhs: Usd, rhs: Usd) -> Usd {
        return Usd(value: lhs.value * rhs.value)
    }
    
    static func *(lhs: Usd, rhs: Int64) -> Usd {
        return Usd(value: lhs.value * rhs)
    }
    
    static func *(lhs: Usd, rhs: Double) -> Usd {
        let result = NSDecimalNumber(value: lhs.value).multiplying(by: NSDecimalNumber(value: rhs))
        return Usd(value: Int64(truncating: result.rounding(accordingToBehavior: NSDecimalNumberHandler.roundDown)))
    }
    
    func toSol(solLamportsInUsCent: NSDecimalNumber) -> Sol {
        let result = NSDecimalNumber(value: self.value).multiplying(by: solLamportsInUsCent)
        return Sol(value: Int64(truncating: result.rounding(accordingToBehavior: NSDecimalNumberHandler.roundDown)))
    }
}

// MARK: - Formatting

extension Usd {
    func abbreviateAmount(fractionDigits: Int = 2) -> String {
        if value == 0 { return "0" }
        let whole = Double(value) / Usd.fractional.precision

        shortFormat.maximumFractionDigits = fractionDigits
        switch whole {
        case let x where x > 1_000_000_000:
            let value = shortFormat.string(from: NSNumber(value: whole / 1_000_000_000)) ?? ""
            return "\(value)B"
        case let x where x > 1_000_000:
            let value = shortFormat.string(from: NSNumber(value: whole / 1_000_000)) ?? ""
            return "\(value)M"
        case let x where x > 1_000:
            let value = shortFormat.string(from: NSNumber(value: whole / 1_000)) ?? ""
            return "\(value)K"
        default:
            return shortFormat.string(from: NSNumber(value: whole)) ?? ""
        }
    }
    
    func abbreviateAmountWithAllZeros() -> String {
        if value == 0 { return "0" }
        let whole = Double(value) / Usd.fractional.precision

        return fullFormat.string(from: NSNumber(value: whole)) ?? ""
    }
    
    func abbreviateAmountWithCurrency(fractionDigits: Int = 2) -> String {
        if let symbolTextRepresentation {
            return symbolTextRepresentation + abbreviateAmount(fractionDigits: fractionDigits)
        } else {
            return abbreviateAmount(fractionDigits: fractionDigits) + " " + code
        }
    }
    
    func string(
        fractionDigits: Int = 2,
        useGroupingSeparator: Bool = true,
        roundingMode: NumberFormatter.RoundingMode = .halfUp
    ) -> String {
        if value == 0 {
            return "0"
        }
        let whole = Double(value) / Usd.fractional.precision
        shortFormat.maximumFractionDigits = fractionDigits
        shortFormat.usesGroupingSeparator = useGroupingSeparator
        shortFormat.roundingMode = roundingMode
        return shortFormat.string(from: NSNumber(value: whole)) ?? ""
    }
    
    func stringWithCurrency(
        fractionDigits: Int = 2,
        useGroupingSeparator: Bool = true,
        roundingMode: NumberFormatter.RoundingMode = .halfUp
    ) -> String {
        if let symbolTextRepresentation {
            return symbolTextRepresentation + string(
                fractionDigits: fractionDigits,
                useGroupingSeparator: useGroupingSeparator,
                roundingMode: roundingMode
            )
        } else {
            return string(
                fractionDigits: fractionDigits,
                useGroupingSeparator: useGroupingSeparator,
                roundingMode: roundingMode
            ) + " " + code
        }
    }
    
    // MARK: -
    var USD: Double {
        Double(truncating: NSDecimalNumber(value: self.value).dividing(by: NSDecimalNumber(value: Usd.fractional.precision)))
    }
    
    var cents: Int {
        Int(value)
    }
}

extension Usd {
    func floored() -> Usd {
        Usd(usd: floor(USD))
    }
    
    var nonZero: Usd? {
        guard value != .zero else {
            return nil
        }
        
        return self
    }
}

private let shortFormat: NumberFormatter = {
    let formatter = NumberFormatter()
    formatter.numberStyle = .decimal
    formatter.decimalSeparator = "."
    formatter.groupingSeparator = ","
    formatter.maximumFractionDigits = 2
    formatter.roundingMode = .halfUp
    return formatter
}()

private let fullFormat: NumberFormatter = {
    let formatter = NumberFormatter()
    formatter.numberStyle = .decimal
    formatter.maximumFractionDigits = Int.max
    formatter.decimalSeparator = "."
    formatter.roundingMode = .down
    return formatter
}()

