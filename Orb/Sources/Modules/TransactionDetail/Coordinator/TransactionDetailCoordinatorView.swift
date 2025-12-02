import ComposableArchitecture
import SwiftUI

struct TransactionDetailCoordinatorView: View {
    
    @Bindable var store: StoreOf<TransactionDetailCoordinator>
    
    var body: some View {
        TransactionDetailView(store: store.scope(state: \.root, action: \.root))
    }
}

