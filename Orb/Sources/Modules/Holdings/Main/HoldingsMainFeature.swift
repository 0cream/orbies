import ComposableArchitecture

@Reducer
struct HoldingsMainFeature {
    @Dependency(\.hapticFeedbackGenerator) var hapticFeedback
    
    var body: some ReducerOf<Self> {
        Reduce<State, Action> { state, action in
            switch action {
            case .view(.didAppear):
                return .none
                
            case .view(.didTapBack):
                return .merge(
                    .run { _ in await hapticFeedback.light(intensity: 1.0) },
                    .send(.delegate(.didRequestBack))
                )
                
            case .view(.didTapToken(let item)):
                return .merge(
                    .run { _ in await hapticFeedback.light(intensity: 1.0) },
                    .send(.delegate(.didRequestNavigateToTokenDetails(item: item)))
                )
                
            case .reducer(.loadHoldings):
                return .none
                
            case .delegate:
                return .none
            }
        }
    }
}

