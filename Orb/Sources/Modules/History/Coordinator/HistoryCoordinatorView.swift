import ComposableArchitecture
import SwiftUI

struct HistoryCoordinatorView: View {
    
    @Bindable var store: StoreOf<HistoryCoordinator>
    
    var body: some View {
        HistoryMainView(store: store.scope(state: \.root, action: \.root))
            .sheet(
                item: $store.scope(state: \.destination?.transactionDetail, action: \.destination.transactionDetail)
            ) { store in
                TransactionDetailCoordinatorView(store: store)
                    .presentationDetents([.medium, .large])
                    .presentationDragIndicator(.visible)
            }
    }
}

