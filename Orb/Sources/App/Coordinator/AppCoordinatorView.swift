import ComposableArchitecture
import SwiftUI
import Dependencies

struct AppCoordinatorView: View {
    
    @Dependency(\.walletService) var walletService
    enum Constants {
        @MainActor
        static let transition: AnyTransition = .complex(
            blur: 4,
            opacity: 0,
            insertionDelay: 0.15,
            animation: .easeOut(duration: 0.15)
        )
    }
    
    // MARK: - Properties
    
    @Bindable var store: StoreOf<AppCoordinator>
    @State private var isDebugPresented = false
    
    // MARK: - UI
    
    var body: some View {
        ZStack {
            switch store.case {
            case let .tabBar(store):
                TabBarCoordinatorView(store: store)
                    .zIndex(1)
                    .transition(Constants.transition)
                
            case let .walletImport(store):
                WalletImportCoordinatorView(store: store)
                    .zIndex(0)
                    .transition(Constants.transition)
                
            case let .accountActivation(store):
                AccountActivationCoordinatorView(store: store)
                    .zIndex(0)
                    .transition(Constants.transition)
                
            case let .onboarding(store):
                OnboardingCoordinatorView(store: store)
                    .zIndex(0)
                    .transition(Constants.transition)
                
            case let .auth(store):
                AuthCoordinatorView(store: store)
                    .zIndex(0)
                    .transition(Constants.transition)
                
            case let .splash(store):
                SplashView(store: store)
                    .zIndex(0)
                    .transition(Constants.transition)
                
            case let .maintenance(store):
                MaintenanceCoordinatorView(store: store)
                    .zIndex(0)
                    .transition(Constants.transition)
            }
        }
        .preferredColorScheme(.dark)
        .onShake {
            Task { @MainActor in
                let publicKey = try await walletService.getPublicKey()
                if publicKey == "2VvuCz7sM2PooNTotYupQ7NbHY3c66Zag8R8QWD9Kg4m" {
                    isDebugPresented = true
                }
            }
        }
        .sheet(isPresented: $isDebugPresented) {
            DebugCoordinatorView(
                store: Store(initialState: DebugCoordinator.State()) {
                    DebugCoordinator()
                }
            )
            .presentationDetents([.medium, .large])
            .presentationDragIndicator(.visible)
        }
    }
}
