import ComposableArchitecture
import SwiftUI

@ViewAction(for: EarnMainFeature.self)
struct EarnMainView: View {
    
    let store: StoreOf<EarnMainFeature>
    
    var body: some View {
        ZStack {
            // Dark background
            Color.black
                .ignoresSafeArea()
            
            ScrollView(.vertical, showsIndicators: false) {
                VStack(spacing: 24) {
                    // Header with back button
                    headerView
                        .padding(.horizontal, 20)
                        .padding(.top, 8)
                    
                    // Balance section
                    balanceSection
                        .padding(.horizontal, 20)
                    
                    // Earnings cards
                    earningsSection
                        .padding(.horizontal, 20)
                    
                    // Investments section (hSOL + active stakes)
                    if store.hsolBalance > 0 || !store.activeValidators.isEmpty {
                        VStack(alignment: .leading, spacing: 16) {
                            Text("Investments")
                                .font(.system(size: 20, weight: .bold))
                                .foregroundColor(.white)
                            
                            // hSOL balance
                            if store.hsolBalance > 0 {
                                hsolBalanceSection
                            }
                            
                            // Active stakes
                            ForEach(store.activeValidators) { stake in
                                activeStakeCardCompact(stake)
                            }
                        }
                        .padding(.horizontal, 20)
                    }
                    
                    // Available products section
                    availableProductsSection
                        .padding(.horizontal, 20)
                    
                    // Bottom spacing
                    Spacer()
                        .frame(height: 100)
                }
            }
        }
        .navigationBarHidden(true)
        .onAppear {
            send(.didAppear)
        }
    }
    
    // MARK: - Header
    
    private var headerView: some View {
        HStack(spacing: 12) {
            // Orb icon
            Image("orb_small_orange")
                .resizable()
                .frame(width: 44, height: 44)
            
            Text("Earn")
                .font(.system(size: 28, weight: .bold))
                .foregroundColor(.white)
            
            Spacer()
            
            // Close button
            Button {
                send(.didTapClose)
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white.opacity(0.6))
                    .frame(width: 32, height: 32)
                    .background(Color.white.opacity(0.1))
                    .clipShape(Circle())
            }
        }
    }
    
    // MARK: - Balance Section
    
    private var balanceSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Balance")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.white.opacity(0.5))
            
            Text("$\(String(format: "%.2f", store.totalStaked))")
                .font(.system(size: 48, weight: .bold))
                .foregroundColor(.white)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.vertical, 8)
    }
    
    // MARK: - hSOL Balance Section
    
    private var hsolBalanceSection: some View {
        HStack(spacing: 12) {
            // hSOL token image
            TokenImageView(
                iconURL: store.hsolImageURL,
                fallbackText: "H",
                size: 48,
                tokenMint: "he1iusmfkpAdwvxLNGV8Y1iSbj4rUy6yMhEA3fotn9A"
            )
            
            VStack(alignment: .leading, spacing: 4) {
                Text("hSOL")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white)
                
                Text("Helius Staked SOL")
                    .font(.system(size: 14, weight: .regular))
                    .foregroundColor(.white.opacity(0.5))
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 4) {
                Text(String(format: "%.4f", store.hsolBalance))
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white)
                
                Text("$\(String(format: "%.2f", store.hsolValueUSD))")
                    .font(.system(size: 14, weight: .regular))
                    .foregroundColor(.white.opacity(0.5))
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white.opacity(0.05))
        )
    }
    
    // MARK: - Earnings Section
    
    private var earningsSection: some View {
        HStack(spacing: 12) {
            // Lifetime Earned Card
            earningCard(
                icon: "chart.line.uptrend.xyaxis",
                title: "Lifetime Earned",
                value: "$\(store.lifetimeEarnedFormatted)"
            )
            
            // Last 7D Card
            earningCard(
                icon: "calendar",
                title: "Last 7D",
                value: "$\(store.last7DaysEarnedFormatted)"
            )
        }
    }
    
    private func earningCard(icon: String, title: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white.opacity(0.6))
                
                Text(title)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.white.opacity(0.6))
            }
            
            Text(value)
                .font(.system(size: 24, weight: .bold))
                .foregroundColor(.white)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white.opacity(0.05))
        )
    }
    
    // MARK: - Available Products
    
    private var availableProductsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Available products")
                .font(.system(size: 20, weight: .bold))
                .foregroundColor(.white)
            
            if store.isLoadingProducts {
                ProgressView()
                    .tint(.white)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, 32)
            } else if store.recommendedValidators.isEmpty {
                emptyProductsView
            } else {
                ForEach(store.recommendedValidators) { product in
                    stakingProductCard(product)
                }
            }
        }
    }
    
    private var emptyProductsView: some View {
        VStack(spacing: 12) {
            Image(systemName: "tray")
                .font(.system(size: 32))
                .foregroundColor(.white.opacity(0.3))
            
            Text("No staking products available")
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(.white.opacity(0.5))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 32)
    }
    
    private func stakingProductCard(_ product: StakingProduct) -> some View {
        Button {
            send(.didTapStakingProduct(product))
        } label: {
            VStack(alignment: .leading, spacing: 12) {
                HStack(spacing: 12) {
                    // Validator icon/logo
                    ZStack {
                        RoundedRectangle(cornerRadius: 12)
                            .fill(
                                product.productType == .staking 
                                    ? Color(hex: "1A1A1A")
                                    : Color(hex: "FF6B35").opacity(0.15)
                            )
                            .frame(width: 56, height: 56)
                        
                        Text(product.productType == .liquidStaking ? "L" : String(product.name.prefix(1)))
                            .font(.system(size: 24, weight: .bold))
                            .foregroundColor(
                                product.productType == .liquidStaking 
                                    ? Color(hex: "FF6B35")
                                    : .white
                            )
                    }
                    
                    VStack(alignment: .leading, spacing: 4) {
                        HStack(spacing: 8) {
                            Text(product.name)
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(.white)
                            
                            Text(product.apyFormatted)
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(Color(hex: "FF6B35"))
                        }
                        
                        Text(product.productTypeTitle)
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.white)
                    }
                    
                    Spacer()
                }
                
                Text(product.description)
                    .font(.system(size: 14, weight: .regular))
                    .foregroundColor(.white.opacity(0.6))
                    .multilineTextAlignment(.leading)
                    .fixedSize(horizontal: false, vertical: true)
                
                // Stats
                HStack(spacing: 16) {
                    statItem(label: "Helius Fees", value: "\(Int(product.commission))%")
                    
                    Divider()
                        .frame(height: 20)
                        .background(Color.white.opacity(0.2))
                    
                    statItem(label: "Validator", value: "Helius")
                    
                    // Only show Total staked for regular staking, not liquid staking
                    if product.productType == .staking {
                        Divider()
                            .frame(height: 20)
                            .background(Color.white.opacity(0.2))
                        
                        statItem(label: "Total staked", value: "\(formatStaked(product.totalStaked))M SOL")
                    }
                }
                
                // Product-specific buttons
                if product.productType == .staking {
                    // Staking: Deposit + Withdraw buttons in HStack
                    HStack(spacing: 12) {
                        Button {
                            send(.didTapDeposit)
                        } label: {
                            HStack(spacing: 8) {
                                Image(systemName: "plus")
                                    .font(.system(size: 16, weight: .semibold))
                                
                                Text("Deposit")
                                    .font(.system(size: 16, weight: .semibold))
                            }
                        }
                        .buttonStyle(.volumeLargeOrange)
                        
                        Button {
                            send(.didTapWithdraw)
                        } label: {
                            HStack(spacing: 8) {
                                Image(systemName: "arrow.up")
                                    .font(.system(size: 16, weight: .semibold))
                                
                                Text("Withdraw")
                                    .font(.system(size: 16, weight: .semibold))
                            }
                            .foregroundColor(.white.opacity(0.5))
                            .frame(maxWidth: .infinity)
                            .frame(height: 72)
                            .background(Color.white.opacity(0.1))
                            .clipShape(RoundedRectangle(cornerRadius: 24))
                        }
                    }
                } else {
                    // Liquid Staking: Full-width Invest button
                    Button {
                        send(.didTapStakingProduct(product))
                    } label: {
                        Text("Invest")
                            .font(.system(size: 16, weight: .semibold))
                    }
                    .buttonStyle(.volumeLargeOrange)
                }
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.white.opacity(0.05))
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private func statItem(label: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label)
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(.white.opacity(0.5))
            
            Text(value)
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(.white)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
    
    // MARK: - Active Stakes (Compact Version for Investments)
    
    private func activeStakeCardCompact(_ stake: ActiveStake) -> some View {
        HStack(spacing: 12) {
            // Validator icon with status indicator
            ZStack(alignment: .bottomTrailing) {
                // Use Helius validator image if it's Helius validator
                if stake.validatorName == "Helius" {
                    Image("helius_validator")
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 48, height: 48)
                        .clipShape(Circle())
                } else {
                    Circle()
                        .fill(Color(hex: "1A1A1A"))
                        .frame(width: 48, height: 48)
                        .overlay(
                            Text(String(stake.validatorName.prefix(1)))
                                .font(.system(size: 20, weight: .bold))
                                .foregroundColor(.white)
                        )
                }
                
                // Status indicator
                Circle()
                    .fill(statusColor(for: stake.status))
                    .frame(width: 12, height: 12)
                    .overlay(
                        Circle()
                            .stroke(Color.black, lineWidth: 2)
                    )
                    .offset(x: 2, y: 2)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(stake.validatorName)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white)
                
                Text("\(stake.statusText) • \(String(format: "%.2f%%", stake.apy)) APY")
                    .font(.system(size: 14, weight: .regular))
                    .foregroundColor(.white.opacity(0.5))
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 4) {
                Text(String(format: "%.4f", stake.amount))
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white)
                
                Text("$\(String(format: "%.2f", stake.valueUSD))") // USD value
                    .font(.system(size: 14, weight: .regular))
                    .foregroundColor(.white.opacity(0.5))
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white.opacity(0.05))
        )
    }
    
    // MARK: - Helpers
    
    private func statusColor(for status: StakeStatus) -> Color {
        switch status {
        case .active:
            return Color(hex: "4ADE80")
        case .activating:
            return Color(hex: "FBBF24")
        case .deactivating:
            return Color(hex: "FB923C")
        case .inactive:
            return Color(hex: "6B7280")
        }
    }
    
    private func formatStaked(_ amount: Double) -> String {
        String(format: "%.2f", amount / 1_000_000)
    }
}

// MARK: - Color Extension

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue:  Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}


