import SwiftUI
import ComposableArchitecture

@main
struct OrbApp: App {
    
    // MARK: - Private Properties
    
    private let store = Store(
        initialState: AppCoordinator.State.splash(
            SplashFeature.State()
        ),
        reducer: {
            AppCoordinator.body
        }
    )
    
    // MARK: - UI
    
    var body: some Scene {
        WindowGroup {
            AppCoordinatorView(store: store)
                .preferredColorScheme(.dark)
        }
    }
}
