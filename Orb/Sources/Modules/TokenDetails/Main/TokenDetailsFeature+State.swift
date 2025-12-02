import ComposableArchitecture
import SwiftUI

extension TokenDetailsFeature {
    @ObservableState
    struct State {
        let token: TokenItem
        var selectedTimeframe: ChartTimeframe = .day
        
        // Price history storage
        var priceHistory: [PricePoint] = []
        var isLoadingPriceHistory: Bool = false
        
        // Cached downsampled data (updated when priceHistory changes)
        var downsampledHistory: [PricePoint] = []
        
        // Chart data - use cached downsampled data
        var chartData: [ChartDataPoint] {
            return downsampledHistory.enumerated().map { index, point in
                ChartDataPoint(index: index, value: point.price, timestamp: point.timestamp)
            }
        }
        
        // Downsample price history to target number of points
        func downsamplePriceHistory(_ history: [PricePoint], targetPoints: Int) -> [PricePoint] {
            guard history.count > targetPoints else {
                return history
            }
            
            let step = Double(history.count) / Double(targetPoints)
            var downsampled: [PricePoint] = []
            
            for i in 0..<targetPoints {
                let index = min(Int(Double(i) * step), history.count - 1)
                downsampled.append(history[index])
            }
            
            // Always include the last point to ensure we show current price
            if let last = history.last, downsampled.last?.timestamp != last.timestamp {
                downsampled[downsampled.count - 1] = last
            }
            
            return downsampled
        }
        
        var chartDataProvider: TokenLineChartDataProvider {
            let lineChartValues = chartData.map { point in
                LineChartValue(x: Double(point.index), y: point.value)
            }
            return TokenLineChartDataProvider(prices: lineChartValues)
        }
        var highlightedChartValue: LineChartValue?
        
        // Real-time price data
        var currentPrice: Double
        var priceChange: Double = 0.0
        
        // Flag to disable animations during chart interaction
        var isHighlighting: Bool {
            highlightedChartValue != nil
        }
        
        // Displayed values (current or highlighted)
        var displayedPrice: Double {
            if let highlighted = highlightedChartValue {
                return highlighted.y
            }
            return currentPrice
        }
        
        var displayedPriceChange: Double {
            // Always show the same price change (don't recalculate when highlighting)
            return priceChange
        }
        
        // User balance (fetched from UserService)
        var userTokensCount: Double = 0.0
        var userTokensValue: Double = 0.0
        var userTokensAmount: Double = 0.0
        var balancePercentage: Int = 0
        
        // Activity popup
        var activityPopup: ActivityPopupValue?
        
        // Stats (from Jupiter data)
        var marketCap: Double
        var liquidity: Double
        var volume24h: Double
        
        // News articles
        var allNewsArticles: [NewsArticle] = []
        
        init(token: TokenItem) {
            self.token = token
            self.currentPrice = token.price
            self.priceHistory = [] // Will be loaded from backend
            self.priceChange = token.priceChange
            self.marketCap = token.marketCap ?? 0.0
            self.liquidity = token.liquidity ?? 0.0
            self.volume24h = token.volume24h ?? 0.0
        }
        
        // Articles relevant to this token and current timeframe
        var relevantArticlesForChart: [NewsArticle] {
            guard !allNewsArticles.isEmpty else { return [] }
            
            // Get time range for current timeframe
            guard let earliestPoint = chartData.first?.timestamp,
                  let latestPoint = chartData.last?.timestamp else {
                return []
            }
            
            // Filter articles that:
            // 1. Have this token
            // 2. Were published within the chart timeframe
            return allNewsArticles.filter { article in
                // Check if article mentions this token
                let hasThisToken = article.tokens.contains { $0.id == token.id }
                
                // Check if article is within timeframe
                let isInTimeframe = article.publishedAt >= earliestPoint && article.publishedAt <= latestPoint
                
                return hasThisToken && isInTimeframe
            }
        }
        
        // MARK: - Helper Methods
        
        mutating func calculatePriceChange(for timeframe: ChartTimeframe) -> Double {
            guard let first = priceHistory.first, let last = priceHistory.last else {
                return 0.0
            }
            
            let change = ((last.price - first.price) / first.price) * 100
            return change
        }
    }
}

// MARK: - Models

struct TokenItem: Equatable, Identifiable {
    let id: String
    let name: String
    let ticker: String
    let imageName: String
    let decimals: Int
    let price: Double
    let priceChange: Double
    let marketCap: Double?
    let liquidity: Double?
    let volume24h: Double?
    
    var priceFormatted: String {
        String(format: "$%.2f", price)
    }
    
    var priceChangeFormatted: String {
        "\(priceChange)%"
    }
}

enum ChartTimeframe: String, CaseIterable, Equatable {
    case day = "1D"
    case week = "1W"
    case month = "1M"
    case year = "1Y"
}

struct ChartDataPoint: Equatable, Identifiable {
    let id = UUID()
    let index: Int
    let value: Double
    let timestamp: Date
}

struct ActivityPopupValue: Equatable {
    let text: String
    let emoji: String
    let id = UUID()
}
