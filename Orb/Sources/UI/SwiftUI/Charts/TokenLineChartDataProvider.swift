import Foundation

struct TokenLineChartDataProvider: Equatable {
    let prices: [LineChartValue]
    
    func data() -> [LineChartValue] {
        return prices
    }
    
    static func == (lhs: TokenLineChartDataProvider, rhs: TokenLineChartDataProvider) -> Bool {
        return lhs.prices == rhs.prices
    }
}

