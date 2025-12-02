import ComposableArchitecture
import SwiftUI

struct MaintenanceCoordinatorView: View {
    
    // MARK: - Properties
    
    @Bindable var store: StoreOf<MaintenanceCoordinator>
    
    // MARK: - UI
    
    var body: some View {
        NavigationStack(
            path: $store.scope(state: \.path, action: \.path),
            root: {
                MaintenanceMainView(store: store.scope(state: \.root, action: \.root))
            },
            destination: { store in
                // - Example:
                // switch store.case {
                // case let .splash(store):
                //     SplashView(store: store)
                // }
            }
        )
        /*
        .sheet(item: $store.scope(state: \.destination?.<#module#>, action: \.destination.<#module#>)) { store in
            <#Module#>View(store: store)
        }
        */
    }
}
