import ComposableArchitecture
import Foundation

@Reducer
struct NewsArticleDetailFeature {
    
    @Dependency(\.hapticFeedbackGenerator) var hapticFeedback
    
    var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case let .view(action):
                return reduce(state: &state, action: action)
                
            case .delegate:
                return .none
            }
        }
    }
    
    // MARK: - View Actions
    
    private func reduce(state: inout State, action: Action.View) -> Effect<Action> {
        switch action {
        case .didTapClose:
            return .merge(
                .run { _ in
                    await hapticFeedback.light(intensity: 1.0)
                },
                .send(.delegate(.didFinish))
            )
        }
    }
}

