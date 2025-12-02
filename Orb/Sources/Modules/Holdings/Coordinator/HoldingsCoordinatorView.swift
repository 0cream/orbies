import ComposableArchitecture
import SwiftUI

struct HoldingsCoordinatorView: View {
    
    @Bindable var store: StoreOf<HoldingsCoordinator>
    
    var body: some View {
        HoldingsMainView(store: store.scope(state: \.main, action: \.main))
    }
}

