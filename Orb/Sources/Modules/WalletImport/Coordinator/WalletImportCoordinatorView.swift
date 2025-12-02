import SwiftUI
import ComposableArchitecture

struct WalletImportCoordinatorView: View {
    
    // MARK: - Properties
    
    let store: StoreOf<WalletImportCoordinator>
    
    // MARK: - UI
    
    var body: some View {
        WalletImportView(store: store.scope(state: \.root, action: \.root))
    }
}


