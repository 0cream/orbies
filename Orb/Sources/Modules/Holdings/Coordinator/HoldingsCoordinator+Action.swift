import ComposableArchitecture

extension HoldingsCoordinator {
    @CasePathable
    enum Action {
        enum Delegate {
            case didFinish
            case didRequestNavigateToTokenDetails(item: PortfolioTokenItem)
        }
        
        case path(StackActionOf<Path>)
        case main(HoldingsMainFeature.Action)
        case delegate(Delegate)
    }
}

extension HoldingsCoordinator {
    @Reducer
    enum Path {
        // Empty - Portfolio handles all navigation from Holdings
    }
}

