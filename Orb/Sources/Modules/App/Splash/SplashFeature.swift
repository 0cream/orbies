import ComposableArchitecture
import Dependencies

@Reducer
struct SplashFeature {
    
    // MARK: - Dependencies
    
    @Dependency(\.appSetupService)
    private var appSetupService: AppSetupService
    
    @Dependency(\.walletService)
    private var walletService: WalletService
    
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
        case .onAppear:
            return .run { send in
                do {
                    try await appSetupService.setup()
                    try await Task.sleep(for: .seconds(1))
                    
                    // Check wallet and signal result
                    let hasWallet = await walletService.hasWallet()
                    
                    if hasWallet {
                        await send(.delegate(.didCompleteWithWallet))
                    } else {
                        await send(.delegate(.didCompleteWithoutWallet))
                    }
                    
                } catch {
                    await send(.delegate(.didRequestMaintenance))
                }
            }
        }
    }
    
    private func reduce(state: inout State, action: Action.Reducer) -> Effect<Action> {
        // No reducer actions currently
        switch action {
        }
    }
} 
