import ComposableArchitecture

extension HoldingsMainFeature {
    @ObservableState
    struct State: Equatable {
        var title: String = "Holdings"
        var tokenHoldings: [PortfolioTokenItem] = []
        var isLoading: Bool = false
        
        init(title: String = "Holdings", tokenHoldings: [PortfolioTokenItem] = []) {
            self.title = title
            self.tokenHoldings = tokenHoldings
        }
    }
}

