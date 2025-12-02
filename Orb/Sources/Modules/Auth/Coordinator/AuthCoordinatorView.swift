import ComposableArchitecture
import SwiftUI

struct AuthCoordinatorView: View {
    
    // MARK: - Properties
    
    @Bindable var store: StoreOf<AuthCoordinator>
    
    // MARK: - UI
    
    var body: some View {
        NavigationStack(
            path: $store.scope(state: \.path, action: \.path),
            root: {
                AuthMainView(store: store.scope(state: \.root, action: \.root))
            },
            destination: { store in
                switch store.case {
                case let .authWebView(store):
                    AuthWebViewView(store: store)
                    
                case let .walletImport(store):
                    WalletImportCoordinatorView(store: store)
                }
            }
        )
    }
}
