import ComposableArchitecture
import Dependencies
import SwiftNavigation

@Reducer
enum AppCoordinator {
    case splash(SplashFeature)
    case walletImport(WalletImportCoordinator)
    case accountActivation(AccountActivationCoordinator)
    case onboarding(OnboardingCoordinator)
    case auth(AuthCoordinator)
    case tabBar(TabBarCoordinator)
    case maintenance(MaintenanceCoordinator)
    
    // MARK: - Reducer
    
    public static var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case let .splash(.delegate(action)):
                return reduce(state: &state, action: action)
            
            case let .walletImport(.delegate(action)):
                return reduce(state: &state, action: action)
            
            case let .accountActivation(.delegate(action)):
                return reduce(state: &state, action: action)
            
            case let .onboarding(.delegate(action)):
                return reduce(state: &state, action: action)
            
            case let .auth(.delegate(action)):
                return reduce(state: &state, action: action)
                
            case let .tabBar(.delegate(action)):
                return reduce(state: &state, action: action)
                
            case let .maintenance(.delegate(action)):
                return reduce(state: &state, action: action)
                
            case .splash, .walletImport, .accountActivation, .onboarding, .auth, .tabBar, .maintenance:
                return .none
            }
        }
        .ifCaseLet(\.splash, action: \.splash) {
            SplashFeature()
        }
        .ifCaseLet(\.walletImport, action: \.walletImport) {
            WalletImportCoordinator()
        }
        .ifCaseLet(\.accountActivation, action: \.accountActivation) {
            AccountActivationCoordinator()
        }
        .ifCaseLet(\.onboarding, action: \.onboarding) {
            OnboardingCoordinator()
        }
        .ifCaseLet(\.auth, action: \.auth) {
            AuthCoordinator()
        }
        .ifCaseLet(\.tabBar, action: \.tabBar) {
            TabBarCoordinator()
        }
        .ifCaseLet(\.maintenance, action: \.maintenance) {
            MaintenanceCoordinator()
        }
    }

    // MARK: - Flow

    private static func reduce(state: inout State, action: SplashFeature.Action.Delegate) -> Effect<Action> {
        switch action {
        case .didCompleteWithWallet:
            // Has wallet - go to main
            print("✅ AppCoordinator: Wallet found, going to TabBar")
            state = .tabBar(TabBarCoordinator.State())
            
            return .run { _ in
                @Dependency(\.userService) var userService
                @Dependency(\.portfolioHistoryService) var portfolioHistoryService
                
                await userService.refreshBalances()
                await portfolioHistoryService.startBackgroundFetch()
            }
            
        case .didCompleteWithoutWallet:
            // No wallet - show onboarding
            print("👋 AppCoordinator: No wallet, showing onboarding")
            state = .onboarding(OnboardingCoordinator.State())
            return .none
            
        case .didRequestMaintenance:
            state = .maintenance(MaintenanceCoordinator.State())
            return .none
        }
    }
    
    private static func reduce(state: inout State, action: WalletImportCoordinator.Action.Delegate) -> Effect<Action> {
        switch action {
        case .didClose:
            // User backed out of wallet import
            return .none
            
        case .didComplete:
            // After wallet import, show account activation screen
            state = .accountActivation(AccountActivationCoordinator.State())
            return .none
        }
    }
    
    private static func reduce(state: inout State, action: AccountActivationCoordinator.Action.Delegate) -> Effect<Action> {
        switch action {
        case .didComplete:
            // After activation, go to main app (tabBar)
            state = .tabBar(TabBarCoordinator.State())
            
            // Refresh balances (background fetch is already running from wallet import)
            return .run { _ in
                @Dependency(\.userService) var userService
                
                print("🚀 AppCoordinator: Refreshing balances after account activation...")
                await userService.refreshBalances()
                print("✅ AppCoordinator: Balances refreshed")
                // Note: Portfolio history background fetch already running from wallet import
            }
        }
    }
    
    private static func reduce(state: inout State, action: OnboardingCoordinator.Action.Delegate) -> Effect<Action> {
        switch action {
        case .didComplete:
            // After onboarding completes, check if wallet exists before deciding next step
            // For now, always go to auth (wallet check will happen in auth if needed)
            print("✅ AppCoordinator: Onboarding completed, showing auth")
            state = .auth(AuthCoordinator.State())
            return .none
        }
    }
    
    private static func reduce(state: inout State, action: AuthCoordinator.Action.Delegate) -> Effect<Action> {
        switch action {
        case let .didFinish(source):
            switch source {
            case .emailAuth:
                // Email auth creates embedded wallet - go directly to main app
                print("✅ AppCoordinator: Email auth completed, going to TabBar")
                state = .tabBar(TabBarCoordinator.State())
                
                // Start data fetching after email auth
                return .run { _ in
                    @Dependency(\.userService) var userService
                    @Dependency(\.portfolioHistoryService) var portfolioHistoryService
                    
                    print("🚀 AppCoordinator: Starting data fetch after email auth...")
                    
                    // Refresh balances
                    await userService.refreshBalances()
                    print("✅ AppCoordinator: Balances refreshed")
                    
                    // Start portfolio history fetch
                    print("📊 AppCoordinator: Starting portfolio history fetch...")
                    await portfolioHistoryService.startBackgroundFetch()
                }
                
            case .privateKey:
                // Private key import needs activation screen
                print("✅ AppCoordinator: Private key import completed, showing AccountActivation")
            state = .accountActivation(AccountActivationCoordinator.State())
            return .none
            }
        }
    }
    
    private static func reduce(state: inout State, action: TabBarCoordinator.Action.Delegate) -> Effect<Action> {
        switch action {
        case .didExitWallet:
            // User exited wallet - go back to onboarding
            print("👋 AppCoordinator: User exited wallet, showing onboarding")
            state = .onboarding(OnboardingCoordinator.State())
            return .none
        }
    }
    
    private static func reduce(state: inout State, action: MaintenanceCoordinator.Action.Delegate) -> Effect<Action> {
        return .none
    }
}


