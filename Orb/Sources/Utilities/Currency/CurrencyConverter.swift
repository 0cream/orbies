import Foundation

protocol CurrencyConverter {
    func convertToUsdc(value: AnyCurrency) -> Usdc?
}

struct DefaultCurrencyConverter: CurrencyConverter {
    func convertToUsdc(value: AnyCurrency) -> Usdc? {
        guard let usdc = value.currency as? Usdc else { return nil }
        return usdc
    }
}

