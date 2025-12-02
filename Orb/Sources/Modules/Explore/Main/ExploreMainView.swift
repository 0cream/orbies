import SwiftUI
import ComposableArchitecture
import SFSafeSymbols
import NukeUI
import Nuke

@ViewAction(for: ExploreMainFeature.self)
struct ExploreMainView: View {
    
    let store: StoreOf<ExploreMainFeature>
    
    var body: some View {
        ZStack {
            Color.black
                .ignoresSafeArea()
            
        ScrollView(.vertical) {
            VStack(spacing: 0) {
                // Header
                HStack(spacing: 8) {
                    Image("orb_small_orange")
                        .resizable()
                        .frame(width: 28, height: 28)
                    
                    Text("Explore")
                        .font(.system(size: 28, weight: .bold))
                            .foregroundStyle(.white)
                    
                    Spacer()
                }
                .padding(.horizontal, 24)
                .padding(.top, 16)
                .padding(.bottom, 24)
                
                // Content
                if store.isLoading && store.topTradedTokens.isEmpty {
                    // Loading state
                    VStack(spacing: 12) {
                        ForEach(0..<10, id: \.self) { _ in
                            TokenRowShimmer()
                        }
                    }
                    .padding(.horizontal, 20)
                } else if let errorMessage = store.errorMessage {
                    // Error state
                    VStack(spacing: 16) {
                        Image(systemSymbol: .exclamationmarkTriangle)
                            .font(.system(size: 40))
                            .foregroundStyle(.white.opacity(0.5))
                        
                        Text(errorMessage)
                            .font(.system(size: 16, weight: .medium))
                            .foregroundStyle(.white.opacity(0.6))
                            .multilineTextAlignment(.center)
                    }
                    .padding(.horizontal, 40)
                    .padding(.top, 60)
                } else {
                    // Token list with staggered animations
                    VStack(spacing: 12) {
                        ForEach(Array(store.topTradedTokens.enumerated()), id: \.element.id) { index, token in
                            TokenRowAnimated(token: token, index: index) {
                                send(.didTapToken(token))
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 120) // Space for tab bar
                }
            }
        }
        }
        .onAppear {
            send(.didAppear)
        }
    }
}

// MARK: - Animated Token Row Wrapper

private struct TokenRowAnimated: View {
    let token: JupiterVerifiedToken
    let index: Int
    let action: () -> Void
    
    @State private var appeared = false
    
    var body: some View {
        Button(action: action) {
            TokenRow(token: token)
        }
        .buttonStyle(.plain)
        .opacity(appeared ? 1 : 0)
        .offset(x: appeared ? 0 : 50)
        .onAppear {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.8).delay(Double(index) * 0.05)) {
                appeared = true
            }
        }
    }
}

// MARK: - Token Row

private struct TokenRow: View {
    let token: JupiterVerifiedToken
    
    var body: some View {
        HStack(spacing: 12) {
            // Token icon with shimmer loading
            TokenImageView(
                iconURL: token.icon,
                fallbackText: token.symbol,
                size: 44
            )
            
            // Token info (left side)
            VStack(alignment: .leading, spacing: 4) {
                Text(token.symbol)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(.white)
                
                Text(token.name)
                    .font(.system(size: 14, weight: .regular))
                    .foregroundStyle(.white.opacity(0.6))
                    .lineLimit(1)
            }
            
            Spacer()
            
            // Market data (right side)
            VStack(alignment: .trailing, spacing: 4) {
                // Market cap
                if let mcap = token.mcap {
                    Text(formatMarketCap(mcap))
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(.white)
                } else {
                    Text("--")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(.white.opacity(0.4))
                }
                
                // 24h change
                if let priceChange = token.stats24h?.priceChange {
                    HStack(spacing: 2) {
                        Image(systemSymbol: priceChange >= 0 ? .arrowUp : .arrowDown)
                            .font(.system(size: 10, weight: .bold))
                        Text(formatPercentage(priceChange))
                            .font(.system(size: 14, weight: .medium))
                    }
                    .foregroundStyle(priceChange >= 0 ? .tokens.green : .tokens.red)
                } else {
                    Text("--")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(.white.opacity(0.4))
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(Color.white.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
    
    private func formatMarketCap(_ mcap: Double) -> String {
        if mcap >= 1_000_000_000 {
            return String(format: "$%.2fB", mcap / 1_000_000_000)
        } else if mcap >= 1_000_000 {
            return String(format: "$%.2fM", mcap / 1_000_000)
        } else if mcap >= 1_000 {
            return String(format: "$%.2fK", mcap / 1_000)
        } else {
            return String(format: "$%.2f", mcap)
        }
    }
    
    private func formatPercentage(_ percentage: Double) -> String {
        return String(format: "%.2f%%", abs(percentage))
    }
}

// MARK: - Shimmer Effect

private struct TokenRowShimmer: View {
    @State private var isAnimating = false
    
    var body: some View {
        HStack(spacing: 12) {
            // Icon
            Circle()
                .fill(Color.white.opacity(0.05))
                .frame(width: 44, height: 44)
            
            // Left info
            VStack(alignment: .leading, spacing: 8) {
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color.white.opacity(0.05))
                    .frame(width: 60, height: 12)
                
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color.white.opacity(0.05))
                    .frame(width: 100, height: 10)
            }
            
            Spacer()
            
            // Right info
            VStack(alignment: .trailing, spacing: 8) {
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color.white.opacity(0.05))
                    .frame(width: 80, height: 12)
                
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color.white.opacity(0.05))
                    .frame(width: 60, height: 10)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(Color.white.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .shimmer()
    }
}

