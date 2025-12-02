import ComposableArchitecture
import SwiftNavigation

@Reducer
struct TokenSellCoordinator {
    var body: some Reducer<State, Action> {
        Scope(state: \.root, action: \.root) {
            TokenSellFeature()
        }
        
        Reduce { state, action in
            switch action {
            case let .root(.delegate(action)):
                return reduce(state: &state, action: action)
            
            case let .destination(.presented(action)):
                return reduce(state: &state, action: action)

            case let .path(.element(_, action)):
                return reduce(state: &state, pathAction: action)
                
            case .root, .destination, .path, .delegate:
                return .none
            }
        }
        .forEach(\.path, action: \.path)
        .ifLet(\.$destination, action: \.destination)
    }

    // MARK: - Root
    
    private func reduce(state: inout State, action: TokenSellFeature.Action.Delegate) -> Effect<Action> {
        switch action {
        case let .didFinish(usdcAmount, tokenTicker):
            return .send(.delegate(.didFinish(usdcAmount: usdcAmount, tokenTicker: tokenTicker)))
            
        case let .didFail(error):
            return .send(.delegate(.didFail(error: error)))
            
        case let .didRequestSell(tokenName, tokensAmount, usdcAmount, usdAmount, fee):
            return .send(.delegate(.didRequestSell(
                tokenName: tokenName,
                tokensAmount: tokensAmount,
                usdcAmount: usdcAmount,
                usdAmount: usdAmount,
                fee: fee
            )))
        }
    }

    // MARK: - Destination

    private func reduce(state: inout State, action: Destination.Action) -> Effect<Action> {
        return .none
    }

    // MARK: - Path

    private func reduce(state: inout State, pathAction: Path.Action) -> Effect<Action> {
        return .none
    }
}

