import ComposableArchitecture
import Dependencies
import Foundation
import UIKit

@Reducer
struct TokenDetailsFeature {
    
    // MARK: - Dependencies
    
    @Dependency(\.userService)
    private var userService: UserService
    
    @Dependency(\.orbBackendService)
    private var orbBackendService: OrbBackendService
    
    @Dependency(\.hapticFeedbackGenerator)
    private var hapticFeedback: HapticFeedbackGenerator
    
    private enum CancelID {
        case tokenBalanceStream
    }
    
    // MARK: - Body
    
    var body: some Reducer<State, Action> {
        Reduce { state, action in
            switch action {
            case let .view(action):
                return reduce(state: &state, action: action)
            case let .reducer(action):
                return reduce(state: &state, action: action)
            case .delegate:
                return .none
            }
        }
    }
    
    // MARK: - Reducer
    
    private func reduce(state: inout State, action: Action.View) -> Effect<Action> {
        switch action {
        case .didAppear:
            return .merge(
                .send(.reducer(.fetchUserBalance)),
                .send(.reducer(.loadPriceHistory)),
                .send(.reducer(.loadNews)),
                // Subscribe to token balance updates
                .run { [tokenId = state.token.id] send in
                    let balanceStream = await userService.tokenBalancesStream
                    for await balances in balanceStream {
                        if let balance = balances[tokenId] {
                            await send(.reducer(.tokenBalanceStreamUpdate(balance)))
                        }
                    }
                }
                .cancellable(id: CancelID.tokenBalanceStream)
            )
            
        case .didTapBack:
            return .merge(
                .run { _ in await hapticFeedback.light(intensity: 1.0) },
                .send(.delegate(.didFinish))
            )
            
        case .didTapCopyTicker:
            // TODO: Copy ticker to clipboard
            return .none
            
        case let .didHighlightChart(value):
            state.highlightedChartValue = value
            return .none
            
        case let .didSelectTimeframe(timeframe):
            state.selectedTimeframe = timeframe
            state.highlightedChartValue = nil // Reset highlight when changing timeframe
            state.priceHistory = [] // Clear old data immediately to prevent flashing
            state.downsampledHistory = [] // Clear downsampled cache too
            state.isLoadingPriceHistory = true
            return .merge(
                .run { _ in await hapticFeedback.light(intensity: 1.0) },
                .send(.reducer(.loadPriceHistory))
            )

        case .didTapSell:
            return .merge(
                .run { _ in await hapticFeedback.light(intensity: 1.0) },
                .send(.delegate(.didRequestSellToken(
                    tokenName: state.token.name,
                    tokenTicker: state.token.ticker,
                    tokenMintAddress: state.token.id,
                    tokenDecimals: state.token.decimals,
                    currentPrice: state.currentPrice,
                    venue: .meteoraDBC, // TODO: Determine actual venue based on token state
                    userTokensBalance: state.userTokensCount
                )))
            )
            
        case .didTapBuy:
            return .merge(
                .run { _ in await hapticFeedback.light(intensity: 1.0) },
                .send(.delegate(.didRequestBuyToken(
                    tokenName: state.token.name,
                    tokenTicker: state.token.ticker,
                    tokenMintAddress: state.token.id,
                    tokenDecimals: state.token.decimals,
                    currentPrice: state.currentPrice,
                    venue: .meteoraDBC // TODO: Determine actual venue based on token state
                )))
            )
            
        case .didTapContactNick:
            // Open Telegram
            return .run { _ in
                if let url = URL(string: "https://t.me/fomichfm") {
                    await MainActor.run {
                        UIApplication.shared.open(url)
                    }
                }
            }
            
        case .didTapShareApp:
            return .run { _ in
                await MainActor.run {
                    let testflightLink: String? = "https://testflight.apple.com/join/NA6Y4VUg"
                    
                    let shareText: String
                    if let link = testflightLink {
                        shareText = """
                        yo, check out this app our applicant sent to us 🔥
                        
                        \(link)
                        """
                    } else {
                        shareText = "yo, check out this app our applicant sent to us 🔥"
                    }
                    
                    let itemsToShare: [Any] = [shareText]
                    
                    guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                          let window = windowScene.windows.first,
                          let rootViewController = window.rootViewController else {
                        return
                    }
                    
                    let activityViewController = UIActivityViewController(
                        activityItems: itemsToShare,
                        applicationActivities: nil
                    )
                    
                    // For iPad support
                    if let popoverController = activityViewController.popoverPresentationController {
                        popoverController.sourceView = rootViewController.view
                        popoverController.sourceRect = CGRect(x: rootViewController.view.bounds.midX, y: rootViewController.view.bounds.midY, width: 0, height: 0)
                        popoverController.permittedArrowDirections = []
                    }
                    
                    rootViewController.present(activityViewController, animated: true)
                }
            }
            
        case let .didTapNewsArticle(article):
            return .send(.delegate(.didRequestNavigateToNewsArticle(article: article)))
        }
    }
    
    private func reduce(state: inout State, action: Action.Reducer) -> Effect<Action> {
        switch action {
        case .loadPriceHistory:
            state.isLoadingPriceHistory = true
            return .run { [tokenId = state.token.id, timeframe = state.selectedTimeframe] send in
                print("📊 TokenDetails: Loading price history for \(tokenId) (\(timeframe.rawValue))")
                
                do {
                    let response = try await orbBackendService.getAllPrices(tokenAddress: tokenId)
                    
                    // Select price data based on timeframe
                    let prices: [StoredPrice]
                    switch timeframe {
                    case .day:
                        prices = response.data.day
                    case .week:
                        prices = response.data.week
                    case .month:
                        prices = response.data.month
                    case .year:
                        prices = response.data.year
                    }
                    
                    // Convert to PricePoint
                    let history = prices.map { storedPrice in
                        PricePoint(
                            timestamp: Date(timeIntervalSince1970: TimeInterval(storedPrice.timestamp) / 1000),
                            price: storedPrice.price
                        )
                    }
                    
                    print("✅ TokenDetails: Loaded \(history.count) price points (will be downsampled to ~100)")
                    await send(.reducer(.priceHistoryLoaded(history)))
                } catch {
                    print("❌ TokenDetails: Failed to load price history: \(error.localizedDescription)")
                    // Send empty history on error
                    await send(.reducer(.priceHistoryLoaded([])))
                }
            }
            
        case let .priceHistoryLoaded(history):
            state.isLoadingPriceHistory = false
            state.priceHistory = history
            
            // Downsample to ~100 points for optimal performance
            let downsampled = state.downsamplePriceHistory(history, targetPoints: 100)
            if !history.isEmpty && downsampled.count != history.count {
                print("📊 TokenDetails: Downsampled from \(history.count) to \(downsampled.count) points")
            }
            state.downsampledHistory = downsampled
            
            if let lastPrice = history.last?.price {
                state.currentPrice = lastPrice
            }
            state.priceChange = state.calculatePriceChange(for: state.selectedTimeframe)
            return .none
            
        case .fetchUserBalance:
            return .run { [tokenId = state.token.id, currentPrice = state.currentPrice] send in
                let balance = await userService.getTokenBalance(tokenId: tokenId)
                let balanceDouble = balance.units.doubleValue
                await send(.reducer(.userBalanceUpdated(
                    tokensCount: balanceDouble,
                    tokensValue: balanceDouble * currentPrice
                )))
            }
            
        case let .userBalanceUpdated(tokensCount, tokensValue):
            state.userTokensCount = tokensCount
            state.userTokensValue = tokensValue
            state.userTokensAmount = tokensCount * 1_000_000
            return .none
            
        case let .tokenBalanceStreamUpdate(balance):
            let balanceDouble = balance.units.doubleValue
            state.userTokensCount = balanceDouble
            state.userTokensValue = balanceDouble * state.currentPrice
            state.userTokensAmount = balanceDouble * 1_000_000
            return .none
            
        case let .showActivityPopup(text, emoji, isSuccess):
            state.activityPopup = ActivityPopupValue(text: text, emoji: emoji)
            return .merge(
                .run { [hapticFeedback] _ in
                    if isSuccess {
                        await hapticFeedback.success()
                    } else {
                        await hapticFeedback.error()
                    }
                },
                .run { send in
                    try await Task.sleep(for: .seconds(3))
                    await send(.reducer(.hideActivityPopup))
                }
            )
            
        case .hideActivityPopup:
            state.activityPopup = nil
            return .none
            
        case .loadNews:
            return .run { send in
                @Dependency(\.newsService) var newsService
                
                do {
                    let articles = try await newsService.fetchNews()
                    await send(.reducer(.newsLoaded(articles)))
                } catch {
                    print("⚠️ Failed to fetch news from backend, using fallback")
                    // Fallback to local JSON
                    let articles = NewsArticle.loadFromJSON()
                    await send(.reducer(.newsLoaded(articles.isEmpty ? NewsArticle.mockArticles : articles)))
                }
            }
            
        case let .newsLoaded(articles):
            state.allNewsArticles = articles
            return .none
        }
    }
    
    // MARK: - Helper Methods
    
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
    
    private func formatPercentage(_ value: Double) -> String {
        let sign = value >= 0 ? "+" : ""
        return "\(sign)\(Int(value))%"
    }
} 