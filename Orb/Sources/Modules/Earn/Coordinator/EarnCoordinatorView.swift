import ComposableArchitecture
import SwiftUI

struct EarnCoordinatorView: View {
    
    @Bindable var store: StoreOf<EarnCoordinator>
    
    var body: some View {
        EarnMainView(store: store.scope(state: \.main, action: \.main))
    }
}

