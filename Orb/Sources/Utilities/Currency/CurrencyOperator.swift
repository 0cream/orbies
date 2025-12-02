import Foundation

protocol CurrencyOperator {
    func subsctract(value: AnyCurrency, from operationalValue: AnyCurrency) -> AnyCurrency?
    func add(value: AnyCurrency, to operationalValue: AnyCurrency) -> AnyCurrency?
}

struct UsdcOperator: CurrencyOperator {
    func subsctract(value: AnyCurrency, from operationalValue: AnyCurrency) -> AnyCurrency? {
        guard
            let value = value.currency as? Usdc,
            let operationalValue = operationalValue.currency as? Usdc
        else {
            print("🧧[Currency Operation] substracting \(value) from \(operationalValue)")
            return nil
        }
        
        return (operationalValue - value).asAnyCurrency()
    }
    
    func add(value: AnyCurrency, to operationalValue: AnyCurrency) -> AnyCurrency? {
        guard
            let value = value.currency as? Usdc,
            let operationalValue = operationalValue.currency as? Usdc
        else {
            print("🧧[Currency Operation] adding \(value) to \(operationalValue)")
            return nil
        }
        
        return (operationalValue + value).asAnyCurrency()
    }
}

struct SolanaOperator: CurrencyOperator {
    func subsctract(value: AnyCurrency, from operationalValue: AnyCurrency) -> AnyCurrency? {
        guard
            let value = value.currency as? Sol,
            let operationalValue = operationalValue.currency as? Sol
        else {
            print("🧧[Currency Operation] substracting \(value) from \(operationalValue)")
            return nil
        }
        
        return (operationalValue - value).asAnyCurrency()
    }
    
    func add(value: AnyCurrency, to operationalValue: AnyCurrency) -> AnyCurrency? {
        guard
            let value = value.currency as? Sol,
            let operationalValue = operationalValue.currency as? Sol
        else {
            print("🧧[Currency Operation] adding \(value) to \(operationalValue)")
            return nil
        }
        
        return (operationalValue + value).asAnyCurrency()
    }
}

struct UsdOperator: CurrencyOperator {
    func subsctract(value: AnyCurrency, from operationalValue: AnyCurrency) -> AnyCurrency? {
        guard
            let value = value.currency as? Usd,
            let operationalValue = operationalValue.currency as? Usd
        else {
            print("🧧[Currency Operation] substracting \(value) from \(operationalValue)")
            return nil
        }
        
        return (operationalValue - value).asAnyCurrency()
    }
    
    func add(value: AnyCurrency, to operationalValue: AnyCurrency) -> AnyCurrency? {
        guard
            let value = value.currency as? Usd,
            let operationalValue = operationalValue.currency as? Usd
        else {
            print("🧧[Currency Operation] adding \(value) to \(operationalValue)")
            return nil
        }
        
        return (operationalValue + value).asAnyCurrency()
    }
}

