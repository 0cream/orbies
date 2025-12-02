import ComposableArchitecture
import SwiftNavigation

@Reducer
struct TokenBuyCoordinator {
    var body: some Reducer<State, Action> {
        Scope(state: \.root, action: \.root) {
            TokenBuyFeature()
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
    
    private func reduce(state: inout State, action: TokenBuyFeature.Action.Delegate) -> Effect<Action> {
        switch action {
        case let .didFinish(tokenAmount, tokenTicker):
            return .send(.delegate(.didFinish(tokenAmount: tokenAmount, tokenTicker: tokenTicker)))
            
        case let .didFail(error):
            return .send(.delegate(.didFail(error: error)))
            
        case let .didRequestPurchase(tokenName, tokensAmount, tokensAmountWithFee, usdcAmount, usdAmount, fee):
            return .send(.delegate(.didRequestPurchase(
                tokenName: tokenName,
                tokensAmount: tokensAmount,
                tokensAmountWithFee: tokensAmountWithFee,
                usdcAmount: usdcAmount,
                usdAmount: usdAmount,
                fee: fee
            )))
            
        case let .didRequestTopUp(amount):
            return .send(.delegate(.didRequestTopUp(amount: amount)))
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
