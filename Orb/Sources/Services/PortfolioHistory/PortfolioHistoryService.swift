import Dependencies
import Foundation

// MARK: - Protocol

protocol PortfolioHistoryService: Sendable {
    /// Get complete portfolio value history for all timeframes
    func getPortfolioHistory() async throws -> PortfolioHistory
    
    /// Get portfolio value history for specific timeframe
    func getPortfolioHistory(timeframe: PortfolioTimeframe) async throws -> [PortfolioDataPoint]
    
    /// Start background fetching with automatic retries for queued/indexing tokens
    func startBackgroundFetch() async
    
    /// Clear all cached portfolio data (call on logout)
    func clearCache() async
}

// MARK: - Models

enum PortfolioTimeframe: String, CaseIterable, Sendable {
    case day = "Day"
    case week = "Week"
    case month = "Month"
    case year = "Year"
}

struct PortfolioHistory: Sendable {
    let day: [PortfolioDataPoint]   // 480 points (3m intervals)
    let week: [PortfolioDataPoint]  // 3360 points (3m intervals)
    let month: [PortfolioDataPoint] // 1440 points (30m intervals)
    let year: [PortfolioDataPoint]  // 524+ points (8H intervals)
}

struct PortfolioDataPoint: Sendable {
    let timestamp: Int // milliseconds
    let value: Double // total value in USDC
    let breakdown: [String: TokenValue] // mint address → token value
}

struct TokenValue: Sendable {
    let symbol: String?
    let balance: Double
    let price: Double
    let value: Double // balance × price
}

// MARK: - Live Implementation

actor LivePortfolioHistoryService: PortfolioHistoryService {
    
    // MARK: - Dependencies
    
    @Dependency(\.transactionHistoryService)
    private var transactionHistoryService: TransactionHistoryService
    
    @Dependency(\.orbBackendService)
    private var orbBackendService: OrbBackendService
    
    @Dependency(\.walletService)
    private var walletService: WalletService
    
    @Dependency(\.jupiterService)
    private var jupiterService: JupiterService
    
    @Dependency(\.userService)
    private var userService: UserService
    
    // MARK: - State
    
    private var backgroundFetchTask: Task<Void, Never>?
    private var cachedHistory: PortfolioHistory?
    private var ongoingFetchTask: Task<PortfolioHistory, Error>?
    
    // MARK: - Methods
    
    func getPortfolioHistory() async throws -> PortfolioHistory {
        // Return cached data if available
        if let cached = cachedHistory {
            print("📊 PortfolioHistoryService: Using cached portfolio history (instant)")
            return cached
        }
        
        // If there's already an ongoing fetch, wait for it instead of starting a duplicate
        if let ongoing = ongoingFetchTask {
            print("📊 PortfolioHistoryService: Waiting for ongoing fetch to complete...")
            return try await ongoing.value
        }
        
        // Create and store the fetch task
        let fetchTask = Task<PortfolioHistory, Error> { [weak self] in
            guard let self = self else {
                throw NSError(domain: "PortfolioHistoryService", code: -1, userInfo: [NSLocalizedDescriptionKey: "Service deallocated"])
            }
            
            let overallStartTime = Date()
            print("📊 PortfolioHistoryService: Fetching complete portfolio history")
            print("⏱️  Start time: \(overallStartTime)")
            
            // Get wallet address
            let walletAddress = try await self.walletService.getPublicKey()
            
            // Get all unique tokens from transaction history
            let allTokens = await self.transactionHistoryService.getUniqueTokens()
        
        guard !allTokens.isEmpty else {
            print("⚠️ PortfolioHistoryService: No tokens found in history")
            return PortfolioHistory(day: [], week: [], month: [], year: [])
        }
        
        print("   Found \(allTokens.count) unique tokens in history")
        
            // ✅ USE CENTRALIZED VERIFIED TOKENS (single source of truth!)
            let verifiedTokensSet = await self.userService.getVerifiedTokens(includeHistorical: true)
            let verifiedTokens = Array(verifiedTokensSet)
            
            print("   ✅ Using \(verifiedTokens.count) verified tokens from UserService")
            
            // ✅ FETCH PRICES ONCE FOR ALL VERIFIED TOKENS
            let fetchStartTime = Date()
            print("   Fetching price data for verified tokens...")
            var tokenPriceData: [String: AllPricesResponse] = [:]
            
            let solMintForFetch = "So11111111111111111111111111111111111111112"
            let usdcMintForFetch = "EPjFWdd5AufqSSqeM2qN1xzybapC8G4wEGGkZwyTDt1v"
            
            for tokenMint in verifiedTokens {
                // Skip USDC - it's always $1 (not indexed by backend)
                if tokenMint == usdcMintForFetch {
                    print("   ⏭️  Skipping USDC (always $1.00)")
                    continue
                }
                
                do {
                    let priceData = try await self.orbBackendService.getAllPrices(tokenAddress: tokenMint)
                    tokenPriceData[tokenMint] = priceData
                    
                    if tokenMint == solMintForFetch {
                        print("   ✅ Fetched prices for SOL (essential!)")
                    } else {
                        print("   ✅ Fetched prices for \(tokenMint.prefix(8))...")
                    }
                } catch OrbBackendError.indexingNotComplete(let status, _) {
                    print("   ⏳ \(tokenMint.prefix(8))... still indexing (\(status))")
                    continue
                } catch {
                    print("   ❌ Failed to fetch prices for \(tokenMint.prefix(8))...: \(error)")
                    continue
                }
            }
            
            let fetchDuration = Date().timeIntervalSince(fetchStartTime)
            print("⏱️  Price fetching took: \(String(format: "%.2f", fetchDuration))s (\(tokenPriceData.count) tokens)")
            
            guard !tokenPriceData.isEmpty else {
                print("⚠️ PortfolioHistoryService: No price data available yet")
                return PortfolioHistory(day: [], week: [], month: [], year: [])
            }
            
            let calculationStartTime = Date()
            print("   Calculating portfolio history for all timeframes...")
            
            // ✅ GET CURRENT BALANCES FROM USERSERVICE (avoids cancelled API calls)
            let currentBalances = await self.userService.getCurrentBalances()
            
            // ✅ USE THE SAME PRICE DATA FOR ALL 4 TIMEFRAMES
            let dayData = await self.calculatePortfolioHistory(
                timeframe: .day,
                tokenPriceData: tokenPriceData,
                walletAddress: walletAddress,
                currentBalances: currentBalances
            )
            let weekData = await self.calculatePortfolioHistory(
                timeframe: .week,
                tokenPriceData: tokenPriceData,
                walletAddress: walletAddress,
                currentBalances: currentBalances
            )
            let monthData = await self.calculatePortfolioHistory(
                timeframe: .month,
                tokenPriceData: tokenPriceData,
                walletAddress: walletAddress,
                currentBalances: currentBalances
            )
            let yearData = await self.calculatePortfolioHistory(
                timeframe: .year,
                tokenPriceData: tokenPriceData,
                walletAddress: walletAddress,
                currentBalances: currentBalances
            )
            
            let calculationDuration = Date().timeIntervalSince(calculationStartTime)
            let totalDuration = Date().timeIntervalSince(overallStartTime)
            
            print("⏱️  Portfolio calculation took: \(String(format: "%.2f", calculationDuration))s")
            print("✅ PortfolioHistoryService: Complete history fetched")
            print("   Day: \(dayData.count) points")
            print("   Week: \(weekData.count) points")
            print("   Month: \(monthData.count) points")
            print("   Year: \(yearData.count) points")
            print("⏱️  TOTAL TIME: \(String(format: "%.2f", totalDuration))s")
            print("   └─ Fetching prices: \(String(format: "%.2f", fetchDuration))s (\(Int((fetchDuration/totalDuration)*100))%)")
            print("   └─ Calculating history: \(String(format: "%.2f", calculationDuration))s (\(Int((calculationDuration/totalDuration)*100))%)")
            
            // Log most recent values across all timeframes for comparison
            if let dayFirst = dayData.first {
                print("   📊 Most recent portfolio values:")
                print("      Day: $\(String(format: "%.2f", dayFirst.value))")
            }
            
            let history = PortfolioHistory(day: dayData, week: weekData, month: monthData, year: yearData)
            
            // Cache for future use
            await self.setCachedHistory(history)
            
            return history
        }
        
        // Store and await the task
        ongoingFetchTask = fetchTask
        defer { ongoingFetchTask = nil }
        
        return try await fetchTask.value
    }
    
    func getPortfolioHistory(timeframe: PortfolioTimeframe) async throws -> [PortfolioDataPoint] {
        // ✅ CHECK CACHE FIRST! If we have cached data, extract the requested timeframe
        if let cached = cachedHistory {
            print("📊 PortfolioHistoryService: Using cached data for \(timeframe.rawValue) (instant)")
            switch timeframe {
            case .day:
                return cached.day
            case .week:
                return cached.week
            case .month:
                return cached.month
            case .year:
                return cached.year
            }
        }
        
        let startTime = Date()
        print("📊 PortfolioHistoryService: Fetching \(timeframe.rawValue) history (single timeframe, no cache)")
        print("⏱️  Start time: \(startTime)")
        
        // Get wallet address
        let walletAddress = try await walletService.getPublicKey()
        
        // Get all unique tokens from transaction history
        let allTokens = await transactionHistoryService.getUniqueTokens()
        
        guard !allTokens.isEmpty else {
            print("⚠️ PortfolioHistoryService: No tokens found in history")
            return []
        }
        
        print("   Found \(allTokens.count) unique tokens in history")
        
        // ✅ USE CENTRALIZED VERIFIED TOKENS (single source of truth!)
        let verifiedTokensSet = await userService.getVerifiedTokens(includeHistorical: true)
        let verifiedTokens = Array(verifiedTokensSet)
        
        print("   ✅ Using \(verifiedTokens.count) verified tokens from UserService")
        
        // Fetch price data for verified tokens
        var tokenPriceData: [String: AllPricesResponse] = [:]
        
        let solMintForFetch = "So11111111111111111111111111111111111111112"
        let usdcMintForFetch = "EPjFWdd5AufqSSqeM2qN1xzybapC8G4wEGGkZwyTDt1v"
        
        for tokenMint in verifiedTokens {
            // Skip USDC - it's always $1 (not indexed by backend)
            if tokenMint == usdcMintForFetch {
                print("   ⏭️  Skipping USDC (always $1.00)")
                continue
            }
            
            do {
                let priceData = try await orbBackendService.getAllPrices(tokenAddress: tokenMint)
                tokenPriceData[tokenMint] = priceData
                
                if tokenMint == solMintForFetch {
                    print("   ✅ Fetched prices for SOL (essential!)")
                } else {
                    print("   ✅ Fetched prices for \(tokenMint.prefix(8))...")
                }
            } catch OrbBackendError.indexingNotComplete(let status, let message) {
                print("   ⏳ \(tokenMint.prefix(8))... still indexing (\(status))")
                if let message = message {
                    print("      \(message)")
                }
                continue
            } catch {
                print("   ❌ Failed to fetch prices for \(tokenMint.prefix(8))...: \(error)")
                continue
            }
        }
        
        guard !tokenPriceData.isEmpty else {
            print("⚠️ PortfolioHistoryService: No price data available yet")
            return []
        }
        
        // ✅ GET CURRENT BALANCES FROM USERSERVICE (avoids cancelled API calls)
        let currentBalances = await userService.getCurrentBalances()
        
        // Calculate portfolio history using the fetched price data
        let result = await calculatePortfolioHistory(
            timeframe: timeframe,
            tokenPriceData: tokenPriceData,
            walletAddress: walletAddress,
            currentBalances: currentBalances
        )
        
        let duration = Date().timeIntervalSince(startTime)
        print("⏱️  Single timeframe fetch took: \(String(format: "%.2f", duration))s (\(result.count) points)")
        
        return result
    }
    
    func startBackgroundFetch() async {
        // Cancel existing fetch if running
        backgroundFetchTask?.cancel()
        
        print("🔄 PortfolioHistoryService: Starting background fetch with progressive retries...")
        
        backgroundFetchTask = Task { [weak self] in
            guard let self = self else { return }
            
            let backgroundStartTime = Date()
            
            // Progressive retry delays: 15s, 20s, 30s, 60s, 90s, 90s, 90s...
            let retryDelays: [UInt64] = [
                15_000_000_000,  // 15s
                20_000_000_000,  // 20s
                30_000_000_000,  // 30s
                60_000_000_000,  // 60s
                90_000_000_000,  // 90s
                90_000_000_000,  // 90s
                90_000_000_000   // 90s
            ]
            
            for attempt in 0..<retryDelays.count {
                do {
                    print("   📊 Attempt \(attempt + 1)/\(retryDelays.count)...")
                    
                    let history = try await self.getPortfolioHistory()
                    
                    // Check if we got valid data
                    if !history.day.isEmpty {
                        await self.setCachedHistory(history)
                        let totalBackgroundDuration = Date().timeIntervalSince(backgroundStartTime)
                        print("✅ PortfolioHistoryService: Background fetch complete!")
                        print("   Day: \(history.day.count) points")
                        print("   Week: \(history.week.count) points")
                        print("   Month: \(history.month.count) points")
                        print("   Year: \(history.year.count) points")
                        print("⏱️  BACKGROUND FETCH TOTAL TIME: \(String(format: "%.2f", totalBackgroundDuration))s (after \(attempt + 1) attempts)")
                        return // Success!
                    } else {
                        let nextDelay = retryDelays[attempt] / 1_000_000_000
                        print("   ⚠️ No data yet, retrying in \(nextDelay)s...")
                    }
                    
                } catch OrbBackendError.indexingNotComplete(let status, let message) {
                    let nextDelay = retryDelays[attempt] / 1_000_000_000
                    print("   ⏳ Backend still indexing (\(status)): \(message ?? "no message")")
                    print("   Retrying in \(nextDelay) seconds...")
                } catch {
                    let nextDelay = retryDelays[attempt] / 1_000_000_000
                    print("   ❌ Error: \(error)")
                    print("   Retrying in \(nextDelay) seconds...")
                }
                
                // Wait before retry (unless it's the last attempt)
                if attempt < retryDelays.count - 1 {
                    try? await Task.sleep(nanoseconds: retryDelays[attempt])
                }
            }
            
            let totalBackgroundDuration = Date().timeIntervalSince(backgroundStartTime)
            print("⚠️ PortfolioHistoryService: All retries exhausted, giving up")
            print("⏱️  BACKGROUND FETCH TOTAL TIME: \(String(format: "%.2f", totalBackgroundDuration))s (\(retryDelays.count) attempts)")
        }
    }
    
    private func setCachedHistory(_ history: PortfolioHistory) async {
        cachedHistory = history
    }
    
    func clearCache() async {
        backgroundFetchTask?.cancel()
        backgroundFetchTask = nil
        ongoingFetchTask?.cancel()
        ongoingFetchTask = nil
        cachedHistory = nil
        print("🗑️ PortfolioHistoryService: Cache cleared")
    }
    
    // MARK: - Private Helper
    
    /// Calculate portfolio history for a specific timeframe using pre-fetched price data
    private func calculatePortfolioHistory(
        timeframe: PortfolioTimeframe,
        tokenPriceData: [String: AllPricesResponse],
        walletAddress: String,
        currentBalances: [String: Double]? = nil
    ) async -> [PortfolioDataPoint] {
        // Get price array for the requested timeframe
        let priceTimestamps = getPriceTimestamps(from: tokenPriceData, timeframe: timeframe)
        
        guard !priceTimestamps.isEmpty else {
            print("⚠️ PortfolioHistoryService: No price timestamps for \(timeframe.rawValue)")
            return []
        }
        
        print("   Processing \(priceTimestamps.count) timestamps for \(timeframe.rawValue)")
        
        // Calculate portfolio value at each timestamp
        var dataPoints: [PortfolioDataPoint] = []
        
        let usdcMint = "EPjFWdd5AufqSSqeM2qN1xzybapC8G4wEGGkZwyTDt1v"
        let solMint = "So11111111111111111111111111111111111111112"
        
        var isFirstTimestamp = true
        var loggedMissingPriceData = false // Track if we've logged missing price data warning
        
        for timestamp in priceTimestamps {
            // Get token balances at this timestamp
            let balances = await transactionHistoryService.getTokenBalancesAt(
                timestamp: timestamp,
                walletAddress: walletAddress,
                currentBalances: currentBalances
            )
            
            // Calculate value for each token
            var breakdown: [String: TokenValue] = [:]
            var totalValue: Double = 0.0
            
            for (tokenMint, balance) in balances {
                let price: Double
                let symbol: String?
                
                // Special cases
                if tokenMint == usdcMint {
                    // USDC is always $1 (stablecoin, not indexed)
                    price = 1.0
                    symbol = "USDC"
                } else if tokenMint == solMint {
                    // SOL - get price from backend
                    guard let priceData = tokenPriceData[tokenMint] else {
                        if !loggedMissingPriceData {
                            print("      ⚠️ No price data for SOL!")
                            loggedMissingPriceData = true
                        }
                        continue
                    }
                    price = findPriceAt(timestamp: timestamp, priceData: priceData, timeframe: timeframe)
                    guard price > 0 else { continue }
                    symbol = "SOL"
                } else {
                    // Other tokens
                    guard let priceData = tokenPriceData[tokenMint] else {
                        // Skip tokens without price data (silently)
                        continue
                    }
                    
                    // Find price closest to this timestamp
                    price = findPriceAt(timestamp: timestamp, priceData: priceData, timeframe: timeframe)
                    guard price > 0 else { continue }
                    symbol = nil
                }
                
                let value = balance * price
                totalValue += value
                
                breakdown[tokenMint] = TokenValue(
                    symbol: symbol,
                    balance: balance,
                    price: price,
                    value: value
                )
            }
            
            dataPoints.append(PortfolioDataPoint(
                timestamp: timestamp,
                value: totalValue,
                breakdown: breakdown
            ))
            
            // Log detailed breakdown for first and last timestamps
            if isFirstTimestamp {
                print("   📊 First timestamp breakdown (most recent):")
                print("      Total value: $\(String(format: "%.2f", totalValue))")
                print("      Tokens included:")
                for (mint, tokenValue) in breakdown.sorted(by: { $0.value.value > $1.value.value }) {
                    let symbol = tokenValue.symbol ?? "\(mint.prefix(8))..."
                    print("         \(symbol): \(String(format: "%.4f", tokenValue.balance)) × $\(String(format: "%.2f", tokenValue.price)) = $\(String(format: "%.2f", tokenValue.value))")
                }
                print("      Tokens in balance but skipped (no price data):")
                for (mint, balance) in balances where breakdown[mint] == nil {
                    print("         \(mint.prefix(8))...: \(String(format: "%.4f", balance))")
                }
                isFirstTimestamp = false
            }
        }
        
        // Log final summary
        if let firstPoint = dataPoints.first, let lastPoint = dataPoints.last {
            let change = ((lastPoint.value - firstPoint.value) / firstPoint.value) * 100
            print("✅ PortfolioHistoryService: \(timeframe.rawValue) history ready (\(dataPoints.count) points)")
            print("   Most recent: $\(String(format: "%.2f", firstPoint.value))")
            print("   Oldest: $\(String(format: "%.2f", lastPoint.value))")
            print("   Change: \(String(format: "%.2f", change))%")
        }
        
        return dataPoints
    }
    
    // MARK: - Private Helpers
    
    /// Extract timestamps from price data for a specific timeframe
    private func getPriceTimestamps(
        from tokenPriceData: [String: AllPricesResponse],
        timeframe: PortfolioTimeframe
    ) -> [Int] {
        // Get timestamps from the first token's price data
        guard let firstToken = tokenPriceData.values.first else {
            return []
        }
        
        let prices: [StoredPrice]
        switch timeframe {
        case .day:
            prices = firstToken.data.day
        case .week:
            prices = firstToken.data.week
        case .month:
            prices = firstToken.data.month
        case .year:
            prices = firstToken.data.year
        }
        
        return prices.map { $0.timestamp }
    }
    
    /// Find the price at or closest to a given timestamp
    private func findPriceAt(
        timestamp: Int,
        priceData: AllPricesResponse,
        timeframe: PortfolioTimeframe
    ) -> Double {
        let prices: [StoredPrice]
        switch timeframe {
        case .day:
            prices = priceData.data.day
        case .week:
            prices = priceData.data.week
        case .month:
            prices = priceData.data.month
        case .year:
            prices = priceData.data.year
        }
        
        // Find exact match or closest timestamp
        if let exactMatch = prices.first(where: { $0.timestamp == timestamp }) {
            return exactMatch.price
        }
        
        // Find closest timestamp (binary search would be better for large arrays)
        let closest = prices.min(by: { abs($0.timestamp - timestamp) < abs($1.timestamp - timestamp) })
        return closest?.price ?? 0.0
    }
}

// MARK: - Dependency

extension DependencyValues {
    var portfolioHistoryService: PortfolioHistoryService {
        get { self[PortfolioHistoryServiceKey.self] }
        set { self[PortfolioHistoryServiceKey.self] = newValue }
    }
}

private enum PortfolioHistoryServiceKey: DependencyKey {
    static let liveValue: PortfolioHistoryService = LivePortfolioHistoryService()
    static let testValue: PortfolioHistoryService = { preconditionFailure() }()
}

