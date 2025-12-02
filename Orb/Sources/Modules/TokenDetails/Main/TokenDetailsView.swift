import SwiftUI
import ComposableArchitecture
import SFSafeSymbols

@ViewAction(for: TokenDetailsFeature.self)
struct TokenDetailsView: View {
    
    // MARK: - Properties
    
    let store: StoreOf<TokenDetailsFeature>
    
    // MARK: - UI
    
    var body: some View {
        ZStack {
            Color.black
                .ignoresSafeArea()
            
        VStack(spacing: 0) {
            // Custom Navigation Bar
            NavigationBarView(
                configuration: NavigationBarConfiguration(
                    title: store.token.name,
                    subtitle: String(format: "$%.5f", store.displayedPrice),
                    showTrailingButton: false
                ),
                action: { action in
                    switch action {
                    case .didTapLeading:
                        send(.didTapBack)
                    case .didTapTrailing:
                        break // No trailing button
                    }
                }
            )
            .padding(.top, 8)
            
            ScrollView(.vertical, showsIndicators: false) {
                VStack(spacing: 0) {
                    // Header with price and name
                    TokenDetailsHeaderView(
                        token: store.token,
                        currentPrice: store.displayedPrice,
                        priceChange: store.displayedPriceChange,
                        isHighlighting: store.isHighlighting,
                        onCopyTicker: { send(.didTapCopyTicker) }
                    )
                    .padding(.horizontal, 24)
                    .padding(.top, 16)
                
                // Chart
                ZStack {
                    if store.isLoadingPriceHistory || store.chartData.isEmpty {
                        // Shimmer while loading (maintains height)
                        ChartShimmerView()
                            .frame(height: 200)
                    } else {
                        OptimizedChart(
                            dataProvider: store.chartDataProvider,
                            accentColor: store.displayedPriceChange >= 0 ? .tokens.green : .tokens.red,
                            numberOfLabels: 0,
                            axisLabel: { _ in EmptyView() },
                            useSmoothedSelection: false,
                            onHighlightChange: { value in
                                send(.didHighlightChart(value))
                            }
                        )
                        .id("\(store.selectedTimeframe.rawValue)-\(store.chartData.count)")
                    }
                }
                .frame(height: 200)
                .padding(.horizontal, 24)
                .padding(.top, 16)
                
                // News article timeline (if any relevant articles)
                if !store.relevantArticlesForChart.isEmpty {
                    NewsTimelineView(
                        articles: store.relevantArticlesForChart,
                        chartData: store.chartData,
                        onArticleTap: { article in
                            send(.didTapNewsArticle(article))
                        }
                    )
                    .padding(.horizontal, 24)
                    .padding(.top, 12)
                }
                
                // Timeframe Selector
                HStack(spacing: 16) {
                    ForEach(ChartTimeframe.allCases, id: \.self) { timeframe in
                        Button {
                            send(.didSelectTimeframe(timeframe))
                        } label: {
                            Text(timeframe.rawValue)
                                .font(.system(size: 12, weight: store.selectedTimeframe == timeframe ? .semibold : .medium))
                                .foregroundStyle(store.selectedTimeframe == timeframe ? .white : .white.opacity(0.5))
                        }
                    }
                }
                .padding(.horizontal, 24)
                .padding(.top, 16)
                
                // Stats Grid
                TokenDetailsStatsView(
                    marketCap: store.marketCap,
                    liquidity: store.liquidity,
                    volume24h: store.volume24h
                )
                .padding(.horizontal, 24)
                .padding(.top, 24)
                
                // Your Balance
                TokenDetailsBalanceView(
                    tokensCount: store.userTokensCount,
                    value: store.userTokensValue,
                    tokensAmount: store.userTokensAmount,
                    tokenTicker: store.token.ticker,
                    tokenImageName: store.token.imageName,
                    percentage: store.balancePercentage,
                    onSell: { send(.didTapSell) },
                    onBuy: { send(.didTapBuy) }
                )
                .padding(.horizontal, 24)
                .padding(.top, 24)
                
                // Bottom padding
                Color.clear
                    .frame(height: 100)
                }
                }
            }
        }
        .overlay(alignment: .top) {
            ActivityPopupView(value: store.activityPopup)
        }
        .animation(.default, value: store.activityPopup?.id)
        .navigationBarHidden(true)
        .onAppear {
            send(.didAppear)
        }
    }
}

// MARK: - Header View

struct TokenDetailsHeaderView: View {
    let token: TokenItem
    let currentPrice: Double
    let priceChange: Double
    let isHighlighting: Bool
    let onCopyTicker: () -> Void
    
    var priceFormatted: String {
        String(format: "$%.5f", currentPrice)
    }
    
    var priceChangeFormatted: String {
        guard priceChange.isFinite else { return "+0%" }
        let sign = priceChange >= 0 ? "+" : ""
        return "\(sign)\(String(format: "%.1f", priceChange))%"
    }
    
    var body: some View {
        ZStack(alignment: .topTrailing) {
            HStack(spacing: 12) {
                TokenImageView(
                    iconURL: token.imageName,
                    fallbackText: token.ticker,
                    size: 48
                )
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(priceFormatted)
                        .font(.system(size: 27, weight: .medium))
                            .foregroundStyle(.white)
                        .contentTransition(.numericText())
                        .animation(.default, value: currentPrice)
                    
                    HStack(spacing: 4) {
                        Text(token.name)
                            .font(.system(size: 14, weight: .medium))
                                .foregroundStyle(.white.opacity(0.6))
                        
                        Button(action: onCopyTicker) {
                            SFSymbol.documentOnDocument.image
                                .font(.system(size: 14))
                                    .foregroundStyle(.white.opacity(0.6))
                        }
                        .buttonStyle(.responsive(.default))
                    }
                }
                
                Spacer()
            }
            
            HStack(spacing: 0) {
                Text(priceChangeFormatted)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(priceChange >= 0 ? .tokens.green : .tokens.red)
                    .if(!isHighlighting) { view in
                        view
                            .contentTransition(.numericText())
                            .animation(.default, value: priceChange)
                    }
                
                (priceChange >= 0 ? SFSymbol.arrowUpRightCircleFill : SFSymbol.arrowDownRightCircleFill).image
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(priceChange >= 0 ? .tokens.green : .tokens.red)
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 6)
            .background(
                priceChange >= 0 ? .tokens.greenBackground : Color.tokens.red.opacity(0.1),
                in: RoundedRectangle(cornerRadius: 12)
            )
        }
    }
}

// MARK: - Chart Helpers

private func formatTimestamp(_ index: Double, for timeframe: ChartTimeframe, chartData: [ChartDataPoint]) -> String {
    let formatter = DateFormatter()
    
    switch timeframe {
    case .day:
        formatter.dateFormat = "HH:mm"
    case .week:
        formatter.dateFormat = "EEE"
    case .month:
        formatter.dateFormat = "d MMM"
    case .year:
        formatter.dateFormat = "MMM yy"
    }
    
    // Get the actual timestamp from chart data
    let pointIndex = Int(index)
    guard pointIndex >= 0 && pointIndex < chartData.count else {
        return ""
    }
    
    let date = chartData[pointIndex].timestamp
    return formatter.string(from: date)
}

// MARK: - Stats View

struct TokenDetailsStatsView: View {
    let marketCap: Double
    let liquidity: Double
    let volume24h: Double
    
    var marketCapFormatted: String {
        formatCurrency(marketCap)
    }
    
    var liquidityFormatted: String {
        formatCurrency(liquidity)
    }
    
    var volume24hFormatted: String {
        formatCurrency(volume24h)
    }
    
    private func formatCurrency(_ value: Double) -> String {
        if value >= 1_000_000 {
            return String(format: "$%.2fM", value / 1_000_000)
        } else if value >= 1_000 {
            return String(format: "$%.2fK", value / 1_000)
        } else {
            return String(format: "$%.2f", value)
        }
    }
    
    private func formatNumber(_ value: Int) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        return formatter.string(from: NSNumber(value: value)) ?? "\(value)"
    }
    
    var body: some View {
        VStack(spacing: 16) {
            // Top separator
            Rectangle()
                .fill(Color.white.opacity(0.1))
                .frame(height: 2)
            
            HStack(spacing: 16) {
                StatItemView(
                    title: "Market cap",
                    value: marketCapFormatted,
                    numericValue: marketCap
                )
                
                StatItemView(
                    title: "Liquidity",
                    value: liquidityFormatted,
                    numericValue: liquidity
                )
                
                StatItemView(
                    title: "Volume 24h",
                    value: volume24hFormatted,
                    numericValue: volume24h
                )
                
                Spacer()
            }
            .padding(.horizontal, 4)
            
            // Bottom separator
            Rectangle()
                .fill(Color.white.opacity(0.1))
                .frame(height: 2)
        }
    }
}

struct StatItemView: View {
    let title: String
    let value: String
    let numericValue: Double?
    
    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title)
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(.white.opacity(0.6))
                .lineLimit(1)
            
            Text(value)
                .font(.system(size: 20, weight: .medium))
                .foregroundStyle(.white)
                .lineLimit(1)
                .contentTransition(.numericText())
                .if(numericValue != nil) { view in
                    view.animation(.default, value: numericValue)
                }
        }
    }
}

// MARK: - Balance View

struct TokenDetailsBalanceView: View {
    let tokensCount: Double
    let value: Double
    let tokensAmount: Double
    let tokenTicker: String
    let tokenImageName: String
    let percentage: Int
    let onSell: () -> Void
    let onBuy: () -> Void
    
    var tokensFormatted: String {
        let millions = tokensAmount / 1_000_000
        return String(format: "%.1fM %@", millions, tokenTicker)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            VStack(alignment: .leading, spacing: 4) {
                Text("Your balance")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(.white.opacity(0.5))
                
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 8) {
                        TokenImageView(
                            iconURL: tokenImageName,
                            fallbackText: tokenTicker,
                            size: 24
                        )
                        
                        Text(String(format: "%.4f tokens", tokensCount))
                            .font(.system(size: 24, weight: .bold))
                            .foregroundStyle(.white)
                            .contentTransition(.numericText())
                            .animation(.default, value: tokensCount)
                    }
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Value")
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundStyle(.white.opacity(0.5))
                        
                    HStack(spacing: 2) {
                        Text("$")
                            .font(.system(size: 18, weight: .bold))
                            .foregroundStyle(.white.opacity(0.4))
                        
                        Text(String(format: "%.2f", value))
                            .font(.system(size: 18, weight: .bold))
                            .foregroundStyle(.white)
                            .contentTransition(.numericText())
                            .animation(.default, value: value)
                    }
                    }
                }
            }
            
            HStack(spacing: 12) {
                Button {
                    onSell()
                } label: {
                    Text("Sell")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 48)
                        .background(Color.white.opacity(0.1), in: .rect(cornerRadius: 16))
                }
                .buttonStyle(.responsive(.default))
                
                Button {
                    onBuy()
                } label: {
                    Text("Buy")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 48)
                        .background(.tokens.green, in: .rect(cornerRadius: 16))
                }
                .buttonStyle(.responsive(.default))
            }
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 20)
        .background(Color.white.opacity(0.08), in: .rect(cornerRadius: 24))
    }
}

// MARK: - Chart Shimmer

private struct ChartShimmerView: View {
    @State private var phase: CGFloat = 0
    
    var body: some View {
        GeometryReader { geometry in
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white.opacity(0.05))
                .overlay(
                    LinearGradient(
                        colors: [
                            Color.clear,
                            Color.white.opacity(0.1),
                            Color.clear
                        ],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                    .frame(width: geometry.size.width * 0.5)
                    .offset(x: phase * geometry.size.width - geometry.size.width * 0.25)
                    .onAppear {
                        withAnimation(.linear(duration: 1.5).repeatForever(autoreverses: false)) {
                            phase = 1
                        }
                    }
                )
        }
    }
}

