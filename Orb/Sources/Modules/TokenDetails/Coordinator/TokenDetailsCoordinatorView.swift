import ComposableArchitecture
import SwiftUI

struct TokenDetailsCoordinatorView: View {
    
    // MARK: - Properties
    
    @Bindable var store: StoreOf<TokenDetailsCoordinator>
    
    // MARK: - UI
    
    var body: some View {
        TokenDetailsView(store: store.scope(state: \.root, action: \.root))
            .sheet(item: $store.scope(state: \.destination?.tokenBuy, action: \.destination.tokenBuy)) { store in
                TokenBuyCoordinatorView(store: store)
                    .presentationDetents([.large])
                    .presentationDragIndicator(.visible)
                    .presentationCornerRadius(40)
                    .presentationBackgroundInteraction(.disabled)
            }
            .sheet(item: $store.scope(state: \.destination?.tokenSell, action: \.destination.tokenSell)) { store in
                TokenSellCoordinatorView(store: store)
                    .presentationDetents([.large])
                    .presentationDragIndicator(.visible)
                    .presentationCornerRadius(40)
                    .presentationBackgroundInteraction(.disabled)
            }
            .sheet(item: $store.scope(state: \.destination?.walletReceive, action: \.destination.walletReceive)) { store in
                WalletReceiveCoordinatorView(store: store)
                    .presentationDetents([.large])
                    .presentationDragIndicator(.visible)
                    .presentationCornerRadius(40)
                    .presentationBackgroundInteraction(.disabled)
            }
    }
}
