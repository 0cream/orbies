import ComposableArchitecture
import Dependencies

@Reducer
struct DebugCoordinator {
    
    @Dependency(\.dismiss) var dismiss
    
    var body: some Reducer<State, Action> {
        Reduce { state, action in
            switch action {
            case let .view(action):
                return reduce(state: &state, action: action)
                
            case let .reducer(action):
                return reduce(state: &state, action: action)
                
            case .root:
                return .none
                
            case .delegate:
                return .none
            }
        }
        
        Scope(state: \.root, action: \.root) {
            DebugFeature()
        }
    }
    
    // MARK: - View Actions
    
    private func reduce(state: inout State, action: Action.View) -> Effect<Action> {
        switch action {
        case .didTapClose:
            return .run { _ in
                await dismiss()
            }
        }
    }
    
    // MARK: - Reducer Actions
    
    private func reduce(state: inout State, action: Action.Reducer) -> Effect<Action> {
        switch action {
        }
    }
}

