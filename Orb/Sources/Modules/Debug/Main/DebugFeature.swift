import ComposableArchitecture
import Dependencies

@Reducer
struct DebugFeature {
    
    @Dependency(\.walletService) var walletService
    @Dependency(\.transactionHistoryService) var transactionHistoryService
    @Dependency(\.orbBackendService) var orbBackendService
    
    var body: some Reducer<State, Action> {
        BindingReducer()
        
        Reduce { state, action in
            switch action {
            case let .view(action):
                return reduce(state: &state, action: action)
                
            case let .reducer(action):
                return reduce(state: &state, action: action)
                
            case .binding:
                return .none
            }
        }
    }
    
    // MARK: - View Actions
    
    private func reduce(state: inout State, action: Action.View) -> Effect<Action> {
        switch action {
        case .didTapClearKeychain:
            state.isClearing = true
            return .run { send in
                do {
                    try await walletService.deleteWallet()
                    print("🗑️ Debug: Keychain cleared")
                    await send(.reducer(.keychainCleared))
                } catch {
                    print("❌ Debug: Failed to clear keychain: \(error)")
                    await send(.reducer(.operationFailed(error.localizedDescription)))
                }
            }
            
        case .didTapClearTransactions:
            state.isClearing = true
            return .run { send in
                await transactionHistoryService.clearHistory()
                print("🗑️ Debug: Transactions cleared")
                await send(.reducer(.transactionsCleared))
            }
            
        case .didTapUpdateEvents:
            state.isUpdatingEvents = true
            return .run { [eventsJSON = state.eventsJSON] send in
                do {
                    let response = try await orbBackendService.updateEvents(eventsJSON: eventsJSON)
                    print("✅ Debug: Events updated - \(response.count) events")
                    await send(.reducer(.eventsUpdated(response.count)))
                } catch {
                    print("❌ Debug: Failed to update events: \(error)")
                    await send(.reducer(.operationFailed(error.localizedDescription)))
                }
            }
            
        case .didTapCrash:
            // Trigger a crash for testing crash reporting
            fatalError("💥 Debug crash triggered intentionally")
        }
    }
    
    // MARK: - Reducer Actions
    
    private func reduce(state: inout State, action: Action.Reducer) -> Effect<Action> {
        switch action {
        case .keychainCleared:
            state.isClearing = false
            state.lastAction = "Keychain cleared ✅"
            return .none
            
        case .transactionsCleared:
            state.isClearing = false
            state.lastAction = "Transactions cleared ✅"
            return .none
            
        case let .eventsUpdated(count):
            state.isUpdatingEvents = false
            state.lastAction = "Events updated ✅ (\(count) events)"
            state.eventsJSON = "" // Clear the input after success
            return .none
            
        case let .operationFailed(error):
            state.isClearing = false
            state.isUpdatingEvents = false
            state.lastAction = "Failed: \(error)"
            return .none
        }
    }
}


