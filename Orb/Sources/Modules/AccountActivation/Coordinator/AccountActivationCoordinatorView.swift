import ComposableArchitecture
import SwiftUI

struct AccountActivationCoordinatorView: View {
    let store: StoreOf<AccountActivationCoordinator>
    
    var body: some View {
        AccountActivationView(
            store: store.scope(state: \.root, action: \.root)
        )
    }
}


