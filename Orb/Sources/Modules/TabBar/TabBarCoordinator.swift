import ComposableArchitecture

@Reducer
struct TabBarCoordinator {
    
    @Dependency(\.walletService) var walletService
    
    var body: some ReducerOf<Self> {
        Scope(state: \.portfolio, action: \.portfolio) {
            PortfolioCoordinator()
        }
        
        Scope(state: \.history, action: \.history) {
            HistoryCoordinator()
        }
        
        Scope(state: \.explore, action: \.explore) {
            ExploreCoordinator()
        }
        
        Reduce { state, action in
            switch action {
            case let .selectedTabChanged(tab):
                state.selectedTab = tab
                return .none
                
            case .didTapOrb:
                state.orbIntelligence = OrbIntelligenceCoordinator.State()
                return .none
                
            case let .portfolio(.delegate(action)):
                return reduce(state: &state, action: action)
                
            case .portfolio:
                return .none
                
            case let .history(.delegate(action)):
                return reduce(state: &state, action: action)
                
            case .history:
                return .none
                
            case .explore:
                return .none
                
            case .orbIntelligence:
                return .none
                
            case .didTapExitWallet:
                state.showExitConfirmation = true
                return .none
                
            case let .setExitConfirmation(show):
                state.showExitConfirmation = show
                return .none
                
            case .confirmExitWallet:
                state.showExitConfirmation = false
                return .run { send in
                    do {
                        try await walletService.deleteWallet()
                        await send(.walletDeleted)
                    } catch {
                        print("❌ Failed to delete wallet: \(error)")
                    }
                }
                
            case .walletDeleted:
                print("✅ Wallet deleted, sending delegate action")
                return .send(.delegate(.didExitWallet))
                
            case .delegate:
                return .none
            }
        }
        .ifLet(\.$orbIntelligence, action: \.orbIntelligence) {
            OrbIntelligenceCoordinator()
        }
    }
    
    // MARK: - Portfolio
    
    private func reduce(state: inout State, action: PortfolioCoordinator.Action.Delegate) -> Effect<Action> {
        // Handle any portfolio delegate actions if needed
        return .none
    }
    
    // MARK: - History
    
    private func reduce(state: inout State, action: HistoryCoordinator.Action.Delegate) -> Effect<Action> {
        // Handle any history delegate actions if needed
        return .none
    }
}

