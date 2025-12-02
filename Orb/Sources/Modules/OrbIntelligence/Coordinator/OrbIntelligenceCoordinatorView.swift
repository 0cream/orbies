import ComposableArchitecture
import SwiftUI

struct OrbIntelligenceCoordinatorView: View {
    
    @Bindable var store: StoreOf<OrbIntelligenceCoordinator>
    
    var body: some View {
        OrbIntelligenceMainView(store: store.scope(state: \.root, action: \.root))
    }
}

