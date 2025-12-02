import ComposableArchitecture

extension HoldingsMainFeature {
    @CasePathable
    enum Action: ViewAction {
        enum View {
            case didAppear
            case didTapBack
            case didTapToken(PortfolioTokenItem)
        }
        
        enum Reducer {
            case loadHoldings
        }
        
        enum Delegate {
            case didRequestBack
            case didRequestNavigateToTokenDetails(item: PortfolioTokenItem)
        }
        
        case view(View)
        case reducer(Reducer)
        case delegate(Delegate)
    }
}

