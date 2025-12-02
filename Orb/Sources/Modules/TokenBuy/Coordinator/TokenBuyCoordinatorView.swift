import SwiftUI
import ComposableArchitecture

struct TokenBuyCoordinatorView: View {
    
    // MARK: - Properties
    
    @Bindable var store: StoreOf<TokenBuyCoordinator>
    
    // MARK: - UI
    
    var body: some View {
        TokenBuyView(store: store.scope(state: \.root, action: \.root))
        /*
        .sheet(item: $store.scope(state: \.destination?.<#module#>, action: \.destination.<#module#>)) { store in
            <#Module#>View(store: store)
        }
        */
    }
}
