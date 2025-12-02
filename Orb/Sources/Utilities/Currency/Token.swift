import Foundation

/// Represents fractional tokens (6 decimal precision like USDC)
struct Token: Codable, Equatable {
    struct Fractional {
        let degree: Int = 6
        var precision: Double { pow(10.0, Double(degree)) }
    }
    
    let value: UInt64
    
    var microunits: UInt64 {
        return value
    }
    
    var fractionalDegree: Int { Token.fractional.degree }
    
    static let fractional: Fractional = Fractional()
    
    // MARK: - Init
    
    init(value: UInt64) {
        self.value = value
    }
    
    init(microunits: UInt64) {
        self.value = microunits
    }
    
    init(units: Double) {
        self.value = UInt64(units * Token.fractional.precision)
    }
    
    init(units: Int64) {
        self.value = UInt64(Double(units) * Token.fractional.precision)
    }
    
    var units: NSDecimalNumber {
        NSDecimalNumber(value: value).dividing(by: NSDecimalNumber(value: Self.fractional.precision))
    }
    
    var decimalUnits: NSDecimalNumber {
        NSDecimalNumber(value: microunits).dividing(by: NSDecimalNumber(value: Token.fractional.precision))
    }
    
    static let zero = Self(value: 0)
}

// MARK: - Operations

extension Token {
    static func +(lhs: Self, rhs: Self) -> Self {
        return Self(value: lhs.value + rhs.value)
    }
    
    func multiplying(by value: Double) -> Token {
        return multiplying(by: NSDecimalNumber(value: value))
    }
    
    func multiplying(by value: NSDecimalNumber) -> Token {
        let result = NSDecimalNumber(value: self.microunits).multiplying(by: value)
        return Token(value: UInt64(truncating: result))
    }
    
    func toMicrounitsInOneMicroUsdc(usdc: Usdc) -> NSDecimalNumber {
        guard usdc != .zero else {
            return .zero
        }
        return NSDecimalNumber(value: microunits)
            .dividing(by: NSDecimalNumber(value: usdc.microUsdc))
    }
    
    func toUsdc(microunitsInOneMicroUsdc: NSDecimalNumber) -> Usdc {
        if microunits == 0 || microunitsInOneMicroUsdc == 0 {
            return .zero
        }
        let result = NSDecimalNumber(value: microunits).dividing(by: microunitsInOneMicroUsdc)
        return Usdc(
            value: Int64(truncating: result.rounding(accordingToBehavior: NSDecimalNumberHandler.roundDown))
        )
    }
}

extension Usdc {
    func toToken(microunitsInOneMicroUsdc: NSDecimalNumber) -> Token {
        let result = NSDecimalNumber(value: microUsdc).multiplying(by: microunitsInOneMicroUsdc)
        return Token(
            microunits: UInt64(
                truncating: result.rounding(accordingToBehavior: NSDecimalNumberHandler.roundDown)
            )
        )
    }
}

