import ComposableArchitecture
import Dependencies

@Reducer
struct AuthMainFeature {
    
    // MARK: - Dependencies
    
    @Dependency(\.hapticFeedbackGenerator)
    private var hapticFeedbackGenerator: HapticFeedbackGenerator
    
    @Dependency(\.authService)
    private var authService: AuthService
    
    // MARK: - Body
    
    var body: some Reducer<State, Action> {
        Reduce { state, action in
            switch action {
            case let .view(action):
                return reduce(state: &state, action: action)
            case let .reducer(action):
                return reduce(state: &state, action: action)
            case .delegate:
                return .none
            }
        }
    }
    
    // MARK: - Reducer
    
    private func reduce(state: inout State, action: Action.View) -> Effect<Action> {
        switch action {
        case .didTapContinueWithEmail:
            return .run { send in
                await hapticFeedbackGenerator.light(intensity: 1.0)
                await send(.delegate(.didRequestAuth(provider: .email)))
            }
            
        case .didTapPrivateKey:
            return .run { send in
                await hapticFeedbackGenerator.light(intensity: 1.0)
                await send(.delegate(.didTapPrivateKey))
            }
        }
    }
    
    private func reduce(state: inout State, action: Action.Reducer) -> Effect<Action> {
        switch action {
        case let .requestAuth(provider):
            return .run { send in
                do {
                    try await authService.auth(with: provider)
                    // TODO: Handle successful auth
                } catch {
                    await send(.reducer(.didFailedAuthorization(error)))
                }
            }
            
        case .didSuccessAuthorization:
            // TODO: Handle successful authorization
            return .none
            
        case .didFailedAuthorization:
            return .run { _ in
                await hapticFeedbackGenerator.error()
            }
        }
    }
}
