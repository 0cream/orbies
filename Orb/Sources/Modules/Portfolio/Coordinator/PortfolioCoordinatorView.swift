import ComposableArchitecture
import SwiftUI

struct PortfolioCoordinatorView: View {
    
    @Bindable var store: StoreOf<PortfolioCoordinator>
    
    var body: some View {
        NavigationStack(
            path: $store.scope(state: \.path, action: \.path)
        ) {
            PortfolioMainView(store: store.scope(state: \.root, action: \.root))
        } destination: { store in
            switch store.case {
            case let .holdings(store):
                HoldingsCoordinatorView(store: store)
                
            case let .tokenDetails(store):
                TokenDetailsCoordinatorView(store: store)
                
            case let .newsArticleDetail(store):
                NewsArticleDetailCoordinatorView(store: store)
                
            case let .earn(store):
                EarnCoordinatorView(store: store)
            }
        }
        .sheet(
            item: $store.scope(state: \.destination?.walletReceive, action: \.destination.walletReceive)
        ) { store in
            WalletReceiveCoordinatorView(store: store)
                .presentationDetents([.large])
                .presentationDragIndicator(.hidden)
        }
    }
}

