import ComposableArchitecture
import SwiftUI

struct WalletReceiveCoordinatorView: View {
    
    let store: StoreOf<WalletReceiveCoordinator>
    
    var body: some View {
        WalletReceiveView(store: store.scope(state: \.root, action: \.root))
    }
}

