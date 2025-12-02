import ComposableArchitecture
import SwiftNavigation

@Reducer
struct OrbIntelligenceCoordinator {
    
    var body: some Reducer<State, Action> {
        Scope(state: \.root, action: \.root) {
            OrbIntelligenceMainFeature()
        }
        
        Reduce { state, action in
            switch action {
            case let .root(.delegate(action)):
                return reduce(state: &state, action: action)
                
            case .root:
                return .none
                
            case .delegate:
                return .none
            }
        }
    }
    
    // MARK: - Root
    
    private func reduce(state: inout State, action: OrbIntelligenceMainFeature.Action.Delegate) -> Effect<Action> {
        switch action {
        // Future delegate actions can be handled here
        }
    }
}

