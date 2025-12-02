import ComposableArchitecture
import SwiftNavigation
import Dependencies

@Reducer
struct AuthCoordinator {
    
    @Dependency(\.walletService) var walletService
    
    var body: some Reducer<State, Action> {
        Scope(state: \.root, action: \.root) {
            AuthMainFeature()
        }
        
        Reduce { state, action in
            switch action {
            case let .root(.delegate(action)):
                return reduce(state: &state, action: action)
                
            case let .path(.element(id: _, action: .authWebView(.delegate(action)))):
                return reduce(state: &state, action: action)
                
            case let .path(.element(id: _, action: .walletImport(.delegate(action)))):
                return reduce(state: &state, action: action)
                
            case .root, .path, .delegate:
                return .none
            }
        }
        .forEach(\.path, action: \.path)
    }

    // MARK: - Root
    
    private func reduce(state: inout State, action: AuthMainFeature.Action.Delegate) -> Effect<Action> {
        switch action {
        case .didTapPrivateKey:
            // Push wallet import screen
            state.path.append(.walletImport(WalletImportCoordinator.State()))
            return .none
            
        case let .didRequestAuth(provider):
            // Push WebView for OAuth
            state.path.append(.authWebView(AuthWebViewFeature.State(provider: provider)))
            return .none
        }
    }
    
    // MARK: - Path - AuthWebView
    
    private func reduce(state: inout State, action: AuthWebViewFeature.Action.Delegate) -> Effect<Action> {
        switch action {
        case .didClose:
            state.path.removeLast()
            return .none
            
        case let .didReceivePrivateKey(privateKey):
            print("🎉 Auth Coordinator received private key from email auth: \(privateKey.prefix(10))...")
            print("💾 Storing private key in keychain...")
            
            // Store private key in keychain via WalletService
            return .run { send in
                do {
                    let publicKey = try await walletService.importWallet(privateKey: privateKey)
                    print("✅ Private key stored successfully!")
                    print("🔑 Public key: \(publicKey)")
                    
                    // Email auth creates embedded wallet - no activation needed
                    await send(.delegate(.didFinish(source: .emailAuth)))
                } catch {
                    print("❌ Failed to store private key: \(error)")
                    // TODO: Handle error - maybe show alert?
                    // For now, continue anyway
                    await send(.delegate(.didFinish(source: .emailAuth)))
                }
            }
        }
    }
    
    // MARK: - Path - WalletImport
    
    private func reduce(state: inout State, action: WalletImportCoordinator.Action.Delegate) -> Effect<Action> {
        switch action {
        case .didClose:
            state.path.removeLast()
            return .none
            
        case .didComplete:
            // Private key import completed - needs activation screen
            return .send(.delegate(.didFinish(source: .privateKey)))
        }
    }
} 
