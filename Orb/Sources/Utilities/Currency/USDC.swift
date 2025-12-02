import Foundation
import UIKit

struct Usdc: Currency, Codable {
    struct Fractional {
        var degree: Int { Int(degreeInt16) }
        var precision: Double { pow(10.0, Double(degree)) }
        
        fileprivate let degreeInt16: Int16 = 6
    }
    
    // MARK: - Meta info
    var code: String { "USDC" }
    var symbolTextRepresentation: String? { "$" }
    var name: String { "Digital Dollars" }
    var decimal: Double { USDC.truncatingRemainder(dividingBy: 1) }
    
    // MARK: - String representation
    var string: String { string() }
    var stringWithCurrency: String { stringWithCurrency() }
    
    /// Internal value in micro-USDC (6 decimals)
    let value: Int64
    /// Fractional degree
    var fractionalDegree: Int { Usdc.fractional.degree }
    
    static let zero = Usdc(value: 0)
    static let one = Usdc(usdc: 1)
    
    static let fractional = Fractional()
    
    // MARK: - Init
    
    init(value: Int64) {
        self.value = value
    }
    
    /// Create USDC from string
    /// - Parameter string: USDC value in string format `1.50`
    init?(string: String) {
        guard let longValue = string
            .replacingNonDigitAndDotSymbols()
            .toLong(fractionalDegree: Usdc.fractional.degree)
        else { return nil }
        self.value = longValue
    }
    
    init(usdc: Double) {
        self.value = Int64(
            truncating: NSDecimalNumber(value: usdc)
                .multiplying(by: NSDecimalNumber(value: Self.fractional.precision))
                .rounding(
                    accordingToBehavior: NSDecimalNumberHandler.handler(scale: Self.fractional.degreeInt16)
                )
        )
    }
    
    func asUICurrency() -> CurrencyUI {
        CurrencyUI(asAnyCurrency())
    }
}

// MARK: - Comparable

extension Usdc: Comparable {
    static func < (lhs: Usdc, rhs: Usdc) -> Bool {
        lhs.value < rhs.value
    }
}

// MARK: - Operators

extension Usdc {
    static func / (lhs: Usdc, rhs: Usdc) -> Usdc {
        Usdc(value: lhs.value / rhs.value)
    }
    static func / (lhs: Usdc, rhs: Double) -> Usdc {
        Usdc(value: Int64(Double(lhs.value) / rhs))
    }
    static func > (lhs: Usdc, rhs: Usdc) -> Bool {
        lhs.value > rhs.value
    }
    static func +(lhs: Usdc, rhs: Usdc) -> Usdc {
        return Usdc(value: lhs.value + rhs.value)
    }
    static func -(lhs: Usdc, rhs: Usdc) -> Usdc {
        return Usdc(value: lhs.value - rhs.value)
    }
    static func *(lhs: Usdc, rhs: Usdc) -> Usdc {
        return Usdc(value: lhs.value * rhs.value)
    }
    static func *(lhs: Usdc, rhs: Int64) -> Usdc {
        return Usdc(value: lhs.value * rhs)
    }
    static func *(lhs: Usdc, rhs: Double) -> Usdc {
        let result = NSDecimalNumber(value: lhs.value)
            .multiplying(by: NSDecimalNumber(value: rhs))
        return Usdc(value: Int64(truncating: result.rounding(accordingToBehavior: NSDecimalNumberHandler.roundDown)))
    }
}

// MARK: - Formatting

extension Usdc {
    func abbreviateAmount(fractionDigits: Int = 2) -> String {
        if value == 0 { return "0" }
        let whole = Double(value) / 1_000_000
        switch whole {
        case let x where x > 1_000_000_000:
            return "\(Int(whole / 1_000_000_000))B"
        case let x where x > 1_000_000:
            return "\(Int(whole / 1_000_000))M"
        case let x where x > 1_000:
            return "\(Int(whole / 1_000))K"
        default:
            shortFormat.maximumFractionDigits = fractionDigits
            return shortFormat.string(from: NSNumber(value: whole)) ?? ""
        }
    }
    
    func abbreviateAmountWithCurrency(fractionDigits: Int = 2) -> String {
        code + abbreviateAmount(fractionDigits: fractionDigits)
    }
    
    func string(
        fractionDigits: Int = 2,
        useGroupingSeparator: Bool = true,
        roundingMode: NumberFormatter.RoundingMode = .down
    ) -> String {
        if value == 0 {
            return "0"
        }
        let whole = Double(value) / 1_000_000
        shortFormat.maximumFractionDigits = fractionDigits
        shortFormat.usesGroupingSeparator = useGroupingSeparator
        shortFormat.roundingMode = roundingMode
        return shortFormat.string(from: NSNumber(value: whole)) ?? ""
    }
    
    func stringWithCurrency(
        fractionDigits: Int = 2,
        useGroupingSeparator: Bool = true,
        roundingMode: NumberFormatter.RoundingMode = .down
    ) -> String {
        if let symbolTextRepresentation {
            return symbolTextRepresentation + string(
                fractionDigits: fractionDigits,
                useGroupingSeparator: useGroupingSeparator,
                roundingMode: roundingMode
            )
        } else {
            return code + string(
                fractionDigits: fractionDigits,
                useGroupingSeparator: useGroupingSeparator,
                roundingMode: roundingMode
            )
        }
    }
    
    // MARK: -
    var USDC: Double {
        Double(
            truncating: NSDecimalNumber(value: self.value)
                .dividing(by: NSDecimalNumber(value: 1_000_000))
        )
    }
    
    var microUsdc: Int64 {
        value
    }
}

extension Usdc {
    func floored() -> Usdc {
        Usdc(usdc: floor(USDC))
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

