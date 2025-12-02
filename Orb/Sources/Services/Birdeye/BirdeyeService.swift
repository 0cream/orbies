import Dependencies
import Foundation

// MARK: - Protocol

protocol BirdeyeService: Actor {
    
    // MARK: - Setup
    
    func setup() async throws
    
    // MARK: - Price History
    
    /// Get historical price data for charts
    func getPriceHistory(
        mint: String,
        timeframe: BirdeyeTimeframe
    ) async throws -> [BirdeyePricePoint]
    
    /// Get OHLCV candles for advanced charts
    func getOHLCV(
        mint: String,
        timeframe: BirdeyeTimeframe,
        interval: BirdeyeInterval
    ) async throws -> [BirdeyeCandle]
    
    // MARK: - Token Overview
    
    /// Get comprehensive token overview (price, volume, market cap, etc.)
    func getTokenOverview(mint: String) async throws -> BirdeyeTokenOverview
    
    /// Get token security info (mint/freeze authority, liquidity locks)
    func getTokenSecurity(mint: String) async throws -> BirdeyeSecurityInfo
    
    // MARK: - Market Data
    
    /// Get trending tokens
    func getTrendingTokens(limit: Int) async throws -> [BirdeyeTrendingToken]
    
    /// Get top gainers
    func getTopGainers(limit: Int) async throws -> [BirdeyeTrendingToken]
    
    /// Get top losers
    func getTopLosers(limit: Int) async throws -> [BirdeyeTrendingToken]
    
    /// Get new listings
    func getNewListings(limit: Int) async throws -> [BirdeyeTrendingToken]
}

// MARK: - Live Implementation

actor LiveBirdeyeService: BirdeyeService {
    
    // MARK: - Properties
    
    private let apiKey = "YOUR_BIRDEYE_API_KEY" // Get from birdeye.so
    private let baseURL = "https://public-api.birdeye.so"
    
    // MARK: - State
    
    private var cachedPriceHistory: [String: [BirdeyePricePoint]] = [:]
    
    // MARK: - Setup
    
    func setup() async throws {
        print("🐦 BirdeyeService: Setup complete")
        print("   API: \(baseURL)")
    }
    
    // MARK: - Price History
    
    func getPriceHistory(
        mint: String,
        timeframe: BirdeyeTimeframe
    ) async throws -> [BirdeyePricePoint] {
        let url = URL(string: "\(baseURL)/defi/history_price?address=\(mint)&type=\(timeframe.rawValue)")!
        
        var request = URLRequest(url: url)
        request.setValue(apiKey, forHTTPHeaderField: "X-API-KEY")
        
        let (data, _) = try await URLSession.shared.data(for: request)
        let response = try JSONDecoder().decode(BirdeyePriceHistoryResponse.self, from: data)
        
        guard response.success else {
            throw BirdeyeServiceError.apiError(response.message ?? "Unknown error")
        }
        
        let pricePoints = response.data.items.map { item in
            BirdeyePricePoint(
                timestamp: Date(timeIntervalSince1970: TimeInterval(item.unixTime)),
                price: item.value
            )
        }
        
        print("🐦 BirdeyeService: Fetched \(pricePoints.count) price points for \(timeframe.rawValue)")
        return pricePoints
    }
    
    func getOHLCV(
        mint: String,
        timeframe: BirdeyeTimeframe,
        interval: BirdeyeInterval
    ) async throws -> [BirdeyeCandle] {
        let url = URL(string: "\(baseURL)/defi/ohlcv?address=\(mint)&type=\(timeframe.rawValue)&interval=\(interval.rawValue)")!
        
        var request = URLRequest(url: url)
        request.setValue(apiKey, forHTTPHeaderField: "X-API-KEY")
        
        let (data, _) = try await URLSession.shared.data(for: request)
        let response = try JSONDecoder().decode(BirdeyeOHLCVResponse.self, from: data)
        
        guard response.success else {
            throw BirdeyeServiceError.apiError(response.message ?? "Unknown error")
        }
        
        let candles = response.data.items.map { item in
            BirdeyeCandle(
                timestamp: Date(timeIntervalSince1970: TimeInterval(item.unixTime)),
                open: item.o,
                high: item.h,
                low: item.l,
                close: item.c,
                volume: item.v
            )
        }
        
        return candles
    }
    
    // MARK: - Token Overview
    
    func getTokenOverview(mint: String) async throws -> BirdeyeTokenOverview {
        let url = URL(string: "\(baseURL)/defi/token_overview?address=\(mint)")!
        
        var request = URLRequest(url: url)
        request.setValue(apiKey, forHTTPHeaderField: "X-API-KEY")
        
        let (data, _) = try await URLSession.shared.data(for: request)
        let response = try JSONDecoder().decode(BirdeyeTokenOverviewResponse.self, from: data)
        
        guard response.success else {
            throw BirdeyeServiceError.apiError(response.message ?? "Unknown error")
        }
        
        return response.data
    }
    
    func getTokenSecurity(mint: String) async throws -> BirdeyeSecurityInfo {
        let url = URL(string: "\(baseURL)/defi/token_security?address=\(mint)")!
        
        var request = URLRequest(url: url)
        request.setValue(apiKey, forHTTPHeaderField: "X-API-KEY")
        
        let (data, _) = try await URLSession.shared.data(for: request)
        let response = try JSONDecoder().decode(BirdeyeSecurityResponse.self, from: data)
        
        guard response.success else {
            throw BirdeyeServiceError.apiError(response.message ?? "Unknown error")
        }
        
        return response.data
    }
    
    // MARK: - Market Data
    
    func getTrendingTokens(limit: Int = 50) async throws -> [BirdeyeTrendingToken] {
        return try await fetchMarketList(endpoint: "defi/tokenlist?sort_by=v24hUSD&sort_type=desc&limit=\(limit)")
    }
    
    func getTopGainers(limit: Int = 50) async throws -> [BirdeyeTrendingToken] {
        return try await fetchMarketList(endpoint: "defi/tokenlist?sort_by=v24hChangePercent&sort_type=desc&limit=\(limit)")
    }
    
    func getTopLosers(limit: Int = 50) async throws -> [BirdeyeTrendingToken] {
        return try await fetchMarketList(endpoint: "defi/tokenlist?sort_by=v24hChangePercent&sort_type=asc&limit=\(limit)")
    }
    
    func getNewListings(limit: Int = 50) async throws -> [BirdeyeTrendingToken] {
        return try await fetchMarketList(endpoint: "defi/tokenlist?sort_by=creationTime&sort_type=desc&limit=\(limit)")
    }
    
    // MARK: - Private Helpers
    
    private func fetchMarketList(endpoint: String) async throws -> [BirdeyeTrendingToken] {
        let url = URL(string: "\(baseURL)/\(endpoint)")!
        
        var request = URLRequest(url: url)
        request.setValue(apiKey, forHTTPHeaderField: "X-API-KEY")
        
        let (data, _) = try await URLSession.shared.data(for: request)
        let response = try JSONDecoder().decode(BirdeyeTokenListResponse.self, from: data)
        
        guard response.success else {
            throw BirdeyeServiceError.apiError(response.message ?? "Unknown error")
        }
        
        return response.data.tokens
    }
}

// MARK: - Models

enum BirdeyeTimeframe: String, Codable {
    case minute1 = "1m"
    case minute5 = "5m"
    case minute15 = "15m"
    case hour1 = "1H"
    case hour4 = "4H"
    case day1 = "1D"
    case week1 = "1W"
    case month1 = "1M"
}

enum BirdeyeInterval: String, Codable {
    case minute1 = "1m"
    case minute5 = "5m"
    case minute15 = "15m"
    case hour1 = "1H"
    case hour4 = "4H"
    case day1 = "1D"
}

struct BirdeyePricePoint: Codable, Equatable {
    let timestamp: Date
    let price: Double
}

struct BirdeyeCandle: Codable, Equatable {
    let timestamp: Date
    let open: Double
    let high: Double
    let low: Double
    let close: Double
    let volume: Double
}

struct BirdeyeTokenOverview: Codable {
    let address: String
    let decimals: Int
    let symbol: String
    let name: String
    let logoURI: String?
    let price: Double
    let priceChange24h: Double?
    let volume24h: Double?
    let liquidity: Double?
    let marketCap: Double?
    let holder: Int?
}

struct BirdeyeSecurityInfo: Codable {
    let isMintable: Bool
    let isFreezable: Bool
    let hasFreezableAuthority: Bool
    let hasMintAuthority: Bool
    let topHolders: [BirdeyeHolder]?
}

struct BirdeyeHolder: Codable {
    let address: String
    let balance: Double
    let percentage: Double
}

struct BirdeyeTrendingToken: Codable, Identifiable {
    let address: String
    let symbol: String
    let name: String
    let logoURI: String?
    let price: Double
    let priceChange24h: Double
    let volume24h: Double
    let liquidity: Double?
    let marketCap: Double?
    
    var id: String { address }
}

// MARK: - API Response Models

struct BirdeyePriceHistoryResponse: Codable {
    let success: Bool
    let message: String?
    let data: BirdeyePriceHistoryData
}

struct BirdeyePriceHistoryData: Codable {
    let items: [BirdeyePriceItem]
}

struct BirdeyePriceItem: Codable {
    let unixTime: Int
    let value: Double
}

struct BirdeyeOHLCVResponse: Codable {
    let success: Bool
    let message: String?
    let data: BirdeyeOHLCVData
}

struct BirdeyeOHLCVData: Codable {
    let items: [BirdeyeOHLCVItem]
}

struct BirdeyeOHLCVItem: Codable {
    let unixTime: Int
    let o: Double // open
    let h: Double // high
    let l: Double // low
    let c: Double // close
    let v: Double // volume
}

struct BirdeyeTokenOverviewResponse: Codable {
    let success: Bool
    let message: String?
    let data: BirdeyeTokenOverview
}

struct BirdeyeSecurityResponse: Codable {
    let success: Bool
    let message: String?
    let data: BirdeyeSecurityInfo
}

struct BirdeyeTokenListResponse: Codable {
    let success: Bool
    let message: String?
    let data: BirdeyeTokenListData
}

struct BirdeyeTokenListData: Codable {
    let tokens: [BirdeyeTrendingToken]
}

// MARK: - Errors

enum BirdeyeServiceError: Error, LocalizedError {
    case notInitialized
    case apiError(String)
    case invalidResponse
    
    var errorDescription: String? {
        switch self {
        case .notInitialized:
            return "Birdeye service not initialized. Call setup() first."
        case .apiError(let message):
            return "Birdeye API error: \(message)"
        case .invalidResponse:
            return "Invalid response from Birdeye API"
        }
    }
}

// MARK: - Dependency

extension DependencyValues {
    var birdeyeService: BirdeyeService {
        get { self[BirdeyeServiceKey.self] }
        set { self[BirdeyeServiceKey.self] = newValue }
    }
}

private enum BirdeyeServiceKey: DependencyKey {
    static let liveValue: BirdeyeService = LiveBirdeyeService()
    static let testValue: BirdeyeService = { fatalError("BirdeyeService not mocked for tests") }()
}

