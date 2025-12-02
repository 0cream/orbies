import ComposableArchitecture
import SwiftNavigation

@Reducer
struct MaintenanceCoordinator {
    var body: some Reducer<State, Action> {
        Scope(state: \.root, action: \.root) {
            MaintenanceMainFeature()
        }
        
        Reduce { state, action in
            switch action {
            case let .root(.delegate(action)):
                return reduce(state: &state, action: action)

            case let .path(.element(_, action)):
                return reduce(state: &state, action: action)
                
            case let .destination(action):
                switch action {
                case .dismiss:
                    return .none
                case let .presented(action):
                    return reduce(state: &state, action: action)
                }
                
            case .root, .path:
                return .none
            }
        }
        .forEach(\.path, action: \.path)
        .ifLet(\.$destination, action: \.destination)
    }

    // MARK: - Root
    
    private func reduce(state: inout State, action: MaintenanceMainFeature.Action.Delegate) -> Effect<Action> {
        return .none
    }

    // MARK: - Destination

    private func reduce(state: inout State, action: Destination.Action) -> Effect<Action> {
        return .none
    }

    // MARK: - Path

    private func reduce(state: inout State, action: Path.Action) -> Effect<Action> {
        return .none
    }
} 
