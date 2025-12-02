import SwiftUI
import SFSafeSymbols

struct CustomTabBarView: View {
    @Binding var selectedTab: TabBarCoordinator.State.Tab
    let onOrbTap: () -> Void
    
    var body: some View {
        HStack {
            // Compact tab bar (rounded pill on left)
            HStack(spacing: 4) {
                // Home tab
                TabBarButton(
                    icon: .houseFill,
                    isSelected: selectedTab == .home
                ) {
                    selectedTab = .home
                }
                
                // History tab
                TabBarButton(
                    icon: .clockFill,
                    isSelected: selectedTab == .history
                ) {
                    selectedTab = .history
                }
                
                // Explore tab
                TabBarButton(
                    icon: .sparkleMagnifyingglass,
                    isSelected: selectedTab == .explore
                ) {
                    selectedTab = .explore
                }
                
                // Settings tab
                TabBarButton(
                    icon: .gearshapeFill,
                    isSelected: selectedTab == .settings
                ) {
                    selectedTab = .settings
                }
            }
            .padding(.horizontal, 4)
            .padding(.vertical, 4)
            .background(
                Capsule()
                    .fill(.ultraThinMaterial)
                    .overlay(
                        Capsule()
                            .fill(Color.white.opacity(0.08))
                    )
                    .shadow(color: .black.opacity(0.3), radius: 12, x: 0, y: 4)
            )
            .padding(.leading, 16)
            
            Spacer()
            
            // Orb button (on the right)
            Button(action: onOrbTap) {
                ZStack {
                    Circle()
                        .fill(.ultraThinMaterial)
                        .overlay(
                            Circle()
                                .fill(Color.white.opacity(0.08))
                        )
                        .frame(width: 56, height: 56)
                        .shadow(color: .black.opacity(0.3), radius: 12, x: 0, y: 4)
                    
                    Image("orb_small_orange")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 44, height: 44)
                }
            }
            .padding(.trailing, 16)
        }
        .frame(height: 60)
        .padding(.bottom, 34)
    }
}

struct TabBarButton: View {
    let icon: SFSymbol
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Image(systemSymbol: icon)
                .font(.system(size: 20, weight: .regular))
                .foregroundStyle(isSelected ? .white : Color.white.opacity(0.4))
                .frame(width: 44, height: 44)
                .background(
                    isSelected ? Color.white.opacity(0.15) : Color.clear,
                    in: Circle()
                )
                .contentShape(Circle())
        }
        .buttonStyle(.plain)
    }
}

