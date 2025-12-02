import ComposableArchitecture
import SwiftUI
import SFSafeSymbols

struct TabBarCoordinatorView: View {
    @Bindable var store: StoreOf<TabBarCoordinator>
    
    var body: some View {
        ZStack {
            // Content area
            switch store.selectedTab {
            case .home:
                PortfolioCoordinatorView(
                    store: store.scope(state: \.portfolio, action: \.portfolio)
                )
            case .history:
                HistoryCoordinatorView(
                    store: store.scope(state: \.history, action: \.history)
                )
            case .explore:
                ExploreCoordinatorView(
                    store: store.scope(state: \.explore, action: \.explore)
                )
                
            case .settings:
                SettingsView(
                    onExitWallet: {
                        store.send(.didTapExitWallet)
                    }
                )
            }
            
            // Custom tab bar overlaid at bottom
            VStack {
                Spacer()
                CustomTabBarView(
                    selectedTab: $store.selectedTab.sending(\.selectedTabChanged),
                    onOrbTap: {
                        store.send(.didTapOrb)
                    }
                )
            }
        }
        .ignoresSafeArea(.all, edges: .bottom)
        .sheet(
            item: $store.scope(state: \.orbIntelligence, action: \.orbIntelligence)
        ) { store in
            OrbIntelligenceCoordinatorView(store: store)
                .presentationDetents([.large])
                .presentationDragIndicator(.hidden)
        }
        .alert(
            "Log Out",
            isPresented: $store.showExitConfirmation.sending(\.setExitConfirmation)
        ) {
            Button("Cancel", role: .cancel) { }
            Button("Log Out", role: .destructive) {
                store.send(.confirmExitWallet)
            }
        } message: {
            Text("This will remove your wallet from this device. Make sure you have backed up your private key or seed phrase.")
        }
    }
}

// MARK: - Settings View

struct SettingsView: View {
    let onExitWallet: () -> Void
    
    private var appVersion: String {
        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
        let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
        return "\(version) (\(build))"
    }
    
    var body: some View {
        ZStack {
            Color.black
                .ignoresSafeArea()
            
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    // Header
                    Text("Settings")
                        .font(.system(size: 28, weight: .bold))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 20)
                        .padding(.top, 16)
                    
                    Spacer()
                        .frame(height: 40)
                    
                    // Log Out Button
                    Button(action: onExitWallet) {
                        HStack(spacing: 12) {
                            Image(systemSymbol: .arrowRightSquare)
                                .font(.system(size: 20, weight: .semibold))
                                .foregroundStyle(.red)
                            
                            Text("Log out")
                                .font(.system(size: 17, weight: .semibold))
                                .foregroundStyle(.white)
                            
                            Spacer()
                            
                            Image(systemSymbol: .chevronRight)
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundStyle(.white.opacity(0.4))
                        }
                        .padding(.horizontal, 20)
                        .padding(.vertical, 16)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color.white.opacity(0.08))
                        )
                    }
                    .padding(.horizontal, 20)
                    
                    // Warning text
                    Text("This will remove your wallet from this device. Make sure you have backed up your private key or seed phrase before logging out.")
                        .font(.system(size: 13, weight: .regular))
                        .foregroundStyle(.white.opacity(0.6))
                        .padding(.horizontal, 20)
                        .padding(.top, -8)
                    
                    Spacer()
                    
                    // Footer
                    VStack(spacing: 12) {
                        Image("orb_small_orange")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 40, height: 40)
                        
                        Text("Orb Invest")
                            .font(.system(size: 17, weight: .bold))
                            .foregroundStyle(.white)
                        
                        Text("Version \(appVersion)")
                            .font(.system(size: 13, weight: .regular))
                            .foregroundStyle(.white.opacity(0.6))
                        
                        HStack(spacing: 8) {
                            Link("Privacy Policy", destination: URL(string: "https://orbinvest.xyz/privacy")!)
                                .font(.system(size: 13, weight: .regular))
                                .foregroundStyle(.white.opacity(0.5))
                            
                            Text("•")
                                .font(.system(size: 13, weight: .regular))
                                .foregroundStyle(.white.opacity(0.5))
                            
                            Link("Terms & Conditions", destination: URL(string: "https://orbinvest.xyz/terms")!)
                                .font(.system(size: 13, weight: .regular))
                                .foregroundStyle(.white.opacity(0.5))
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.top, 40)
                    .padding(.bottom, 20)
                }
                .padding(.bottom, 120)
            }
        }
    }
}

