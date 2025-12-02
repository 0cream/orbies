import ComposableArchitecture
import SwiftUI

struct ExploreCoordinatorView: View {
    @Bindable var store: StoreOf<ExploreCoordinator>
    
    var body: some View {
        NavigationStack(path: $store.scope(state: \.path, action: \.path)) {
            ExploreMainView(store: store.scope(state: \.main, action: \.main))
        } destination: { store in
            switch store.case {
            case .tokenDetails(let store):
                TokenDetailsCoordinatorView(store: store)
            }
        }
    }
}

