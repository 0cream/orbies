import Foundation
import UIKit
import SFSafeSymbols

struct Sol: Currency, Codable {
    struct Fractional {
        var degree: Int { Int(degreeInt16) }
        var precision: Double { pow(10.0, Double(degree)) }
        
        fileprivate let degreeInt16: Int16 = 9
    }

    /// Internal value in lamports (9 decimals)
    let value: Int64
    /// Fractional degree
    var fractionalDegree: Int { Sol.fractional.degree }

    // MARK: - Info

    var symbolTextRepresentation: String? { nil }
    var code: String { "SOL" }
    var name: String { "Solana"}
    var decimal: Double { SOL.truncatingRemainder(dividingBy: 1) }

    // MARK: - String Representation
    var string: String { string() }
    var stringWithCurrency: String { stringWithCurrency() }
    
    static let fractional: Fractional = Fractional()

    // MARK: - Init

    init(value: Int64) {
        self.value = value
    }
    
    init(value: UInt64) {
        self.value = Int64(value)
    }

    init(sol: Double) {
        self.value = Int64(
            truncating: NSDecimalNumber(value: sol)
                .multiplying(by: NSDecimalNumber(value: Self.fractional.precision))
                .rounding(
                    accordingToBehavior: NSDecimalNumberHandler.handler(scale: Self.fractional.degreeInt16)
                )
        )
    }

    init?(string: String) {
        guard
            let longValue = string
                .replacingNonDigitAndDotSymbols()
                .toLong(fractionalDegree: Sol.fractional.degree)
        else { return nil }
        self.value = longValue
    }

    static let zero = Sol(sol: 0)
    static let one = Sol(sol: 1.0)

    var solLamports: Int64 { value }
    
    func asUICurrency() -> CurrencyUI {
        CurrencyUI(self.asAnyCurrency())
    }
}

// MARK: - Comparable

extension Sol: Comparable {
    static func < (lhs: Sol, rhs: Sol) -> Bool {
        return lhs.value < rhs.value
    }
}

// MARK: - Operators

extension Sol {
    init?(solLamportsString value: String) {
        guard let longValue = value.replacingNonDigitAndDotSymbols().toLong() else { return nil }
        self.value = longValue
    }

    static func +(lhs: Sol, rhs: Sol) -> Sol {
        return Sol(value: lhs.value + rhs.value)
    }

    static func -(lhs: Sol, rhs: Sol) -> Sol {
        return Sol(value: lhs.value - rhs.value)
    }

    static func *(lhs: Sol, rhs: Sol) -> Sol {
        return Sol(value: lhs.value * rhs.value)
    }

    static func *(lhs: Sol, rhs: Int64) -> Sol {
        return Sol(value: lhs.value * rhs)
    }
    
    static func += (lhs: inout Sol, rhs: Sol) {
        lhs = lhs + rhs
    }

    static func *(lhs: Sol, rhs: Double) -> Sol {
        let result = NSDecimalNumber(value: lhs.value).multiplying(by: NSDecimalNumber(value: rhs))
        return Sol(value: Int64(truncating: result.rounding(accordingToBehavior: NSDecimalNumberHandler.roundDown)))
    }
    
    func multiplying(by value: NSDecimalNumber) -> Sol {
        let result = NSDecimalNumber(value: self.value).multiplying(by: value)
        return Sol(value: Int64(truncating: result.rounding(accordingToBehavior: NSDecimalNumberHandler.roundDown)))
    }

    // nano_sol / nano_sol_in_us_cent (rate) = us_cents_total

    func toUsd(solLamportsInUsCent: NSDecimalNumber) -> Usd {
        return Usd(
            value: Int64(
                truncating: toUsdCentsDecimal(solLamportsInUsCent: solLamportsInUsCent)
                    .rounding(accordingToBehavior: NSDecimalNumberHandler.roundDown)
            )
        )
    }
    
    func toUsdCentsDecimal(solLamportsInUsCent: NSDecimalNumber) -> NSDecimalNumber {
        if self.value == 0 || solLamportsInUsCent == 0 {
            return .zero
        }

        return NSDecimalNumber(value: self.value).dividing(by: solLamportsInUsCent)
    }

    // E.g. you take your balance in SOL
    // and you want it to cost amount in USD that you are passing
    // as a parameter.
    // Method calculates what should the price be to make it happen.
    func toSolLamportsInOneCent(usd: Usd) -> NSDecimalNumber {
        guard usd != .zero else {
            return .zero
        }

        return NSDecimalNumber(value: value).dividing(by: NSDecimalNumber(value: usd.cents))
    }
}

// MARK: - Formatting

extension Sol {
    func abbreviateAmount(fractionDigits: Int = 2) -> String {
        if value == 0 { return "0" }
        let whole = Double(value) / Sol.fractional.precision

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
        if let symbolTextRepresentation {
            return symbolTextRepresentation + abbreviateAmount(fractionDigits: fractionDigits)
        } else {
            return abbreviateAmount(fractionDigits: fractionDigits) + " " + code
        }
    }

    func abbreviateAmountWithAllZeros() -> String {
        if value == 0 { return "0" }
        let whole = Double(value) / Sol.fractional.precision

        return fullFormat.string(from: NSNumber(value: whole)) ?? ""
    }

    // MARK: -

    var SOL: Double {
        Double(truncating: NSDecimalNumber(value: self.value).dividing(by: NSDecimalNumber(value: Sol.fractional.precision)))
    }

    var cuttted: Sol {
        Sol(sol: floor(SOL))
    }

    func string(
        fractionDigits: Int = 2,
        useGroupingSeparator: Bool = false,
        roundingMode: NumberFormatter.RoundingMode = .down
    ) -> String {
        if value == 0 {
            return "0"
        }

        let whole = Double(value) / Sol.fractional.precision

        shortFormat.maximumFractionDigits = fractionDigits
        shortFormat.roundingMode = roundingMode
        shortFormat.usesGroupingSeparator = useGroupingSeparator

        return shortFormat.string(from: NSNumber(value: whole)) ?? ""
    }
    
    func stringWithCurrency(
        fractionDigits: Int = 2,
        useGroupingSeparator: Bool = false,
        roundingMode: NumberFormatter.RoundingMode = .down
    ) -> String {
        if let symbolTextRepresentation {
            symbolTextRepresentation + string(
                fractionDigits: fractionDigits,
                useGroupingSeparator: useGroupingSeparator,
                roundingMode: roundingMode
            )
        } else {
            string(
                fractionDigits: fractionDigits,
                useGroupingSeparator: useGroupingSeparator,
                roundingMode: roundingMode
            ) + " " + code
        }
    }
}

extension Sol {
    func floored() -> Sol {
        Sol(sol: floor(SOL))
    }
}

func abs(_ value: Sol) -> Sol {
    Sol(value: abs(value.value))
}

private let shortFormat: NumberFormatter = {
    let formatter = NumberFormatter()
    formatter.numberStyle = .decimal
    formatter.decimalSeparator = "."
    formatter.groupingSeparator = ","
    formatter.roundingMode = .down
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

