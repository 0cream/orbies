import SwiftUI
import ComposableArchitecture

struct OnboardingCoordinatorView: View {
    
    // MARK: - Properties
    
    let store: StoreOf<OnboardingCoordinator>
    
    // MARK: - UI
    
    var body: some View {
        OnboardingView(store: store.scope(state: \.root, action: \.root))
    }
}

