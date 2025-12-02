import ComposableArchitecture

extension AuthCoordinator {
    @CasePathable
    enum Action {
        enum Delegate {
            case didFinish(source: AuthCompletionSource)
        }
        
        case path(StackActionOf<Path>)
        case root(AuthMainFeature.Action)
        case delegate(Delegate)
    }
}

extension AuthCoordinator {
    @Reducer
    enum Path {
        case authWebView(AuthWebViewFeature)
        case walletImport(WalletImportCoordinator)
    }
}

enum AuthCompletionSource {
    case emailAuth      // Privy email-based auth (embedded wallet)
    case privateKey     // Manual private key import
} 
