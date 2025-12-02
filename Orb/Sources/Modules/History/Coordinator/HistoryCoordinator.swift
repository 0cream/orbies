import ComposableArchitecture
import SwiftNavigation

@Reducer
struct HistoryCoordinator {
    
    var body: some Reducer<State, Action> {
        Scope(state: \.root, action: \.root) {
            HistoryMainFeature()
        }
        
        Reduce { state, action in
            switch action {
            case let .root(.delegate(action)):
                return reduce(state: &state, action: action)
                
            case let .path(.element(_, action)):
                return reduce(state: &state, action: action)
                
            case .root, .path:
                return .none
                
            case .destination(.presented(.transactionDetail(.delegate(.didFinish)))):
                state.destination = nil
                return .none
                
            case .destination(.presented(.transactionDetail)):
                return .none
                
            case .destination(.dismiss):
                state.destination = nil
                return .none
                
            case .destination:
                return .none
                
            case .delegate:
                return .none
            }
        }
        .forEach(\.path, action: \.path)
        .ifLet(\.$destination, action: \.destination)
    }
    
    // MARK: - Root
    
    private func reduce(state: inout State, action: HistoryMainFeature.Action.Delegate) -> Effect<Action> {
        switch action {
        case let .didRequestOpenTransactionDetail(transaction):
            state.destination = .transactionDetail(
                TransactionDetailCoordinator.State(transaction: transaction)
            )
            return .none
        }
    }
    
    // MARK: - Path
    
    private func reduce(state: inout State, action: Path.Action) -> Effect<Action> {
        // No paths yet
        return .none
    }
}

