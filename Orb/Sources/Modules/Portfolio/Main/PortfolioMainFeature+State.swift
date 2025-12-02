import ComposableArchitecture
import Foundation

enum BalanceChangeDirection: Equatable {
    case none
    case up
    case down
}

extension PortfolioMainFeature {
    @ObservableState
    struct State {
        var totalBalance: Usdc = .zero
        var cashBalance: Usdc = .zero
        var investmentsBalance: Usdc = .zero
        
        // Balance change animation
        var previousBalance: Usdc = .zero
        var balanceChangeDirection: BalanceChangeDirection = .none
        
        // Portfolio value history for chart
        var portfolioHistory: [PricePoint] = []
        var portfolioChange24h: Double = 0.0 // Actually tracks change for selected timeframe
        var hasLoadedHistory: Bool = false // Track if we've loaded real data
        
        // Cache for all timeframes (avoid re-fetching)
        var portfolioHistoryCache: [ChartTimeframe: [PricePoint]] = [:]
        var isLoadingHistory: Bool = false
        
        // Token holdings (investments)
        var tokenHoldings: [PortfolioTokenItem] = []
        
        // News articles
        var allNewsArticles: [NewsArticle] = [] // All articles from JSON
        var newsArticles: [NewsArticle] = [] // Currently displayed articles
        var displayedArticlesCount: Int = 10 // Start with 10
        
        // Search
        var isSearchActive: Bool = false
        var searchQuery: String = ""
        var searchResults: [SearchTokenResult] = []
        var isSearching: Bool = false
        
        // Chart data
        var selectedTimeframe: ChartTimeframe = .day
        var highlightedChartValue: LineChartValue?
        
        // Display price (highlighted or current)
        var displayedBalance: Usdc {
            if let highlighted = highlightedChartValue {
                return Usdc(usdc: highlighted.y)
            }
            return totalBalance
        }
        
        var displayedBalanceFormatted: String {
            "$\(String(format: "%.2f", displayedBalance.USDC))"
        }
        
        var displayedDate: String? {
            guard let highlighted = highlightedChartValue else { return nil }
            
            // Find the corresponding timestamp from chartData
            let index = Int(highlighted.x)
            guard index >= 0, index < chartData.count else { return nil }
            
            let timestamp = chartData[index].timestamp
            let formatter = DateFormatter()
            
            // Different format based on timeframe
            switch selectedTimeframe {
            case .day:
                formatter.dateFormat = "MMM d, h:mm a" // "Nov 28, 9:30 PM"
            case .week:
                formatter.dateFormat = "MMM d, h:mm a" // "Nov 28, 9:30 PM"
            case .month:
                formatter.dateFormat = "MMM d, yyyy" // "Nov 28, 2024"
            case .year:
                formatter.dateFormat = "MMM yyyy" // "Nov 2024"
            }
            
            return formatter.string(from: timestamp)
        }
        
        var chartData: [ChartDataPoint] {
            // Use portfolioHistory directly - it's already loaded for the selected timeframe
            return portfolioHistory.enumerated().map { index, point in
                ChartDataPoint(index: index, value: point.price, timestamp: point.timestamp)
            }
        }
        
        var chartDataProvider: TokenLineChartDataProvider {
            let lineChartValues = chartData.map { point in
                LineChartValue(x: Double(point.index), y: point.value)
            }
            return TokenLineChartDataProvider(prices: lineChartValues)
        }
        
        // Formatted strings
        var totalBalanceFormatted: String {
            "$\(String(format: "%.2f", totalBalance.USDC))"
        }
        
        var cashBalanceFormatted: String {
            "$\(String(format: "%.2f", cashBalance.USDC))"
        }
        
        var investmentsBalanceFormatted: String {
            "$\(String(format: "%.2f", investmentsBalance.USDC))"
        }
        
        var portfolioChange24hFormatted: String {
            let prefix = portfolioChange24h >= 0 ? "+" : ""
            return "\(prefix)\(String(format: "%.1f", portfolioChange24h))%"
        }
        
        var portfolioChange24hColor: String {
            portfolioChange24h >= 0 ? "green" : "red"
        }
        
        // Articles relevant to current holdings and timeframe
        var relevantArticlesForChart: [NewsArticle] {
            guard !tokenHoldings.isEmpty, !allNewsArticles.isEmpty else { return [] }
            
            // Get time range for current timeframe
            guard let earliestPoint = chartData.first?.timestamp,
                  let latestPoint = chartData.last?.timestamp else {
                return []
            }
            
            // Get user's token mint addresses
            let userTokenMints = Set(tokenHoldings.map { $0.id })
            
            // Filter articles that:
            // 1. Have tokens that match user's holdings
            // 2. Were published within the chart timeframe
            return allNewsArticles.filter { article in
                // Check if article has any tokens that user holds
                let hasRelevantTokens = article.tokens.contains { token in
                    userTokenMints.contains(token.id)
                }
                
                // Check if article is within timeframe
                let isInTimeframe = article.publishedAt >= earliestPoint && article.publishedAt <= latestPoint
                
                return hasRelevantTokens && isInTimeframe
            }
        }
    }
}

// MARK: - Models

struct PortfolioTokenItem: Equatable, Identifiable {
    let id: String
    let imageName: String
    let title: String
    let subtitle: String
    let decimals: Int
    let price: Double
    let priceChange: Double
    let holdingsAmount: Double
    
    var holdingsValue: Double {
        price * holdingsAmount
    }
    
    var formattedValue: String {
        "$\(String(format: "%.2f", holdingsValue))"
    }
    
    var formattedAmount: String {
        if holdingsAmount >= 1000 {
            return String(format: "%.2fk", holdingsAmount / 1000)
        } else {
            return String(format: "%.2f", holdingsAmount)
        }
    }
}

