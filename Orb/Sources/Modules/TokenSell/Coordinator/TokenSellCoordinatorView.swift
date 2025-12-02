import SwiftUI
import ComposableArchitecture

struct TokenSellCoordinatorView: View {
    
    // MARK: - Properties
    
    @Bindable var store: StoreOf<TokenSellCoordinator>
    
    // MARK: - UI
    
    var body: some View {
        TokenSellView(store: store.scope(state: \.root, action: \.root))
        /*
        .sheet(item: $store.scope(state: \.destination?.<#module#>, action: \.destination.<#module#>)) { store in
            <#Module#>View(store: store)
        }
        */
    }
}

