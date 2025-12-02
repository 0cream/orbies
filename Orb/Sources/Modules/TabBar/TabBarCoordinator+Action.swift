import ComposableArchitecture

extension TabBarCoordinator {
    @CasePathable
    enum Action {
        enum Delegate {
            case didExitWallet
        }
        
        case portfolio(PortfolioCoordinator.Action)
        case history(HistoryCoordinator.Action)
        case explore(ExploreCoordinator.Action)
        case orbIntelligence(PresentationAction<OrbIntelligenceCoordinator.Action>)
        case selectedTabChanged(State.Tab)
        case didTapOrb
        case didTapExitWallet
        case setExitConfirmation(Bool)
        case confirmExitWallet
        case walletDeleted
        case delegate(Delegate)
    }
}

