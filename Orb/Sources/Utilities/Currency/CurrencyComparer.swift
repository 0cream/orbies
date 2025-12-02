import Foundation

enum CurrencyCompareResult {
    case bigger
    case smaller
    case equal
    case wrongCurrencies
}

protocol CurrencyComparer {
    func compare(value: AnyCurrency, to another: AnyCurrency) -> CurrencyCompareResult
}

struct UsdcComparer: CurrencyComparer {
    func compare(value: AnyCurrency, to another: AnyCurrency) -> CurrencyCompareResult {
        guard
            let value = value.currency as? Usdc,
            let another = another.currency as? Usdc
        else {
            return .wrongCurrencies
        }
        
        if value == another { return .equal }
        if value > another { return .bigger }
        return .smaller
    }
}

struct SolanaComparer: CurrencyComparer {
    func compare(value: AnyCurrency, to another: AnyCurrency) -> CurrencyCompareResult {
        guard
            let value = value.currency as? Sol,
            let another = another.currency as? Sol
        else {
            return .wrongCurrencies
        }
        
        if value == another { return .equal }
        if value > another { return .bigger }
        return .smaller
    }
}

