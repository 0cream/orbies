import Foundation

// MARK: - Token Update

struct TokenUpdate: Equatable, Sendable {
    let tokenId: String
    let price: Double
    let priceChange: Double // Percentage
    let liquidity: Double
    let tokenTrades: Int
    let timestamp: Date
    
    // Recent trades in this update
    let recentTrades: [TradeInfo]
}

struct TradeInfo: Equatable, Sendable {
    let buyerName: String
    let solanaAddress: String
    let quantity: Double
    let timestamp: Date
    let avatarImageName: String // e.g., "pengu-1", "pengu-2", etc.
    
    var displayAddress: String {
        // Show first 4 and last 4 characters: "Abc1...xyz9"
        guard solanaAddress.count > 8 else { return solanaAddress }
        let start = solanaAddress.prefix(4)
        let end = solanaAddress.suffix(4)
        return "\(start)...\(end)"
    }
}

// MARK: - Subscription

enum WebSocketSubscription: Equatable, Sendable {
    case allTokens
    case specificToken(id: String, initialPrice: Double)
}
