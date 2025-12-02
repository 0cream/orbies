import ComposableArchitecture

extension PortfolioCoordinator {
    @CasePathable
    enum Action {
        enum Delegate {
            // delegate actions
        }
        
        case path(StackActionOf<Path>)
        case destination(PresentationAction<Destination.Action>)
        case root(PortfolioMainFeature.Action)
        case delegate(Delegate)
    }
}

extension PortfolioCoordinator {
    @Reducer
    enum Path {
        case holdings(HoldingsCoordinator)
        case tokenDetails(TokenDetailsCoordinator)
        case newsArticleDetail(NewsArticleDetailCoordinator)
        case earn(EarnCoordinator)
    }
}

extension PortfolioCoordinator {
    @Reducer
    enum Destination {
        case walletReceive(WalletReceiveCoordinator)
    }
}

