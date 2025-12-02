import Dependencies
import Foundation

// MARK: - Models

struct TokenHoldingMetadata {
    let symbol: String
    let name: String
    let decimals: Int
    let imageURL: String?
    let priceChange24h: Double
}

// MARK: - Protocol

protocol UserService: Actor {
    
    // MARK: - Balance Streams
    
    var solanaBalanceStream: AsyncStream<Sol> { get async }
    var usdcBalanceStream: AsyncStream<Usdc> { get async }
    var tokenBalancesStream: AsyncStream<[String: Token]> { get async }
    
    // MARK: - Current Balances
    
    func getSolanaBalance() async -> Sol
    func getUsdcBalance() async -> Usdc
    func getTokenBalance(tokenId: String) async -> Token
    func getCurrentBalances() async -> [String: Double]
    
    // MARK: - Total Balance
    
    /// Calculates total balance in USDC (all tokens value + USDC balance)
    /// Fetches current prices for all tokens and calculates total
    /// - Returns: Total balance in USDC
    func getTotalBalance() async -> Usdc
    
    // MARK: - Methods
    
    func setup() async throws
    func refreshBalances() async
    func forceRefreshBalances() async
    func startAutoRefresh()
    func stopAutoRefresh()
    func getPublicKey() async throws -> String
    
    // MARK: - Verified Tokens
    
    /// Get all Jupiter-verified tokens (single source of truth!)
    /// - Parameter includeHistorical: Include tokens from transaction history
    /// - Returns: Set of verified token mints (always includes SOL and USDC)
    func getVerifiedTokens(includeHistorical: Bool) async -> Set<String>
    
    // MARK: - Token Holdings
    
    /// Get current token holdings with metadata (for Portfolio/Holdings display)
    /// - Returns: Array of token holdings with balance, price, metadata, decimals
    func getTokenHoldings() async -> [(address: String, symbol: String, name: String, decimals: Int, imageURL: String?, balance: Double, price: Double, priceChange: Double)]
    
    // MARK: - Trading
    
    func buyToken(tokenId: String, usdcAmount: Double, currentPrice: Double) async throws
    func sellToken(tokenId: String, amount: Double, currentPrice: Double) async throws
    func getCurrentPrice(for tokenId: String) async -> Double
}

// MARK: - Live Implementation

actor LiveUserService: UserService {
    
    // MARK: - Dependencies
    
    @Dependency(\.walletService)
    private var walletService: WalletService
    
    @Dependency(\.heliusService)
    private var heliusService: HeliusService
    
    @Dependency(\.solanaService)
    private var solanaService: SolanaService
    
    @Dependency(\.transactionHistoryService)
    private var transactionHistoryService: TransactionHistoryService
    
    @Dependency(\.orbBackendService)
    private var orbBackendService: OrbBackendService
    
    @Dependency(\.jupiterService)
    private var jupiterService: JupiterService
    
    // MARK: - Publishers
    
    private let solanaBalancePublisher = AsyncPublisher<Sol>()
    private let usdcBalancePublisher = AsyncPublisher<Usdc>()
    private let tokenBalancesPublisher = AsyncPublisher<[String: Token]>()
    
    // MARK: - State
    
    private var currentSolanaBalance: Sol = .zero
    private var currentUsdcBalance: Usdc = .zero
    private var currentTokenBalances: [String: Token] = [:]
    private var tokenPrices: [String: Double] = [:] // mint address -> price
    private var tokenMetadata: [String: TokenHoldingMetadata] = [:] // mint address -> metadata
    
    // MARK: - Auto-refresh
    
    private var refreshTask: Task<Void, Never>?
    
    // MARK: - Backend Indexing
    
    /// Tracks tokens that have been submitted to backend for indexing
    /// Key: token mint address
    private var indexedTokens: Set<String> = []
    
    // MARK: - Verified Tokens Cache
    
    /// Single source of truth for verified tokens across the app
    /// All tokens here are Jupiter-verified and safe to use
    private var verifiedTokensCache: Set<String> = []
    private var verifiedTokensCacheTimestamp: Date?
    
    /// Get all verified tokens (current + historical)
    /// ✅ SINGLE SOURCE OF TRUTH - use this everywhere!
    /// Returns: Set of Jupiter-verified token mints that are safe to use
    func getVerifiedTokens(includeHistorical: Bool = false) async -> Set<String> {
        print("🔍 UserService: Getting verified tokens (includeHistorical: \(includeHistorical))")
        
        // Always include SOL and USDC
        var verified: Set<String> = [
            "So11111111111111111111111111111111111111112", // SOL
            "EPjFWdd5AufqSSqeM2qN1xzybapC8G4wEGGkZwyTDt1v"  // USDC
        ]
        
        // Add all tokens from current holdings
        for mint in currentTokenBalances.keys {
            if await jupiterService.isTokenVerified(mint: mint) {
                verified.insert(mint)
            }
        }
        
        // Optionally add historical tokens (from transaction history)
        if includeHistorical {
            let allHistoricalTokens = await transactionHistoryService.getUniqueTokens()
            for mint in allHistoricalTokens {
                // Skip if already added
                if verified.contains(mint) {
                    continue
                }
                
                if await jupiterService.isTokenVerified(mint: mint) {
                    verified.insert(mint)
                }
            }
        }
        
        print("   ✅ Found \(verified.count) verified tokens")
        return verified
    }
    
    // MARK: - Streams
    
    var solanaBalanceStream: AsyncStream<Sol> {
        get async {
            await solanaBalancePublisher.stream()
        }
    }
    
    var usdcBalanceStream: AsyncStream<Usdc> {
        get async {
            await usdcBalancePublisher.stream()
        }
    }
    
    var tokenBalancesStream: AsyncStream<[String: Token]> {
        get async {
            await tokenBalancesPublisher.stream()
        }
    }
    
    // MARK: - Current Balances
    
    func getSolanaBalance() async -> Sol {
        return currentSolanaBalance
    }
    
    func getUsdcBalance() async -> Usdc {
        return currentUsdcBalance
    }
    
    func getTokenBalance(tokenId: String) async -> Token {
        return currentTokenBalances[tokenId] ?? .zero
    }
    
    func getCurrentBalances() async -> [String: Double] {
        var balances: [String: Double] = [:]
        
        // Add SOL
        let solMint = "So11111111111111111111111111111111111111112"
        balances[solMint] = currentSolanaBalance.SOL
        
        // Add USDC
        let usdcMint = "EPjFWdd5AufqSSqeM2qN1xzybapC8G4wEGGkZwyTDt1v"
        balances[usdcMint] = currentUsdcBalance.USDC
        
        // Add all other tokens
        for (tokenId, token) in currentTokenBalances {
            let tokenAmount = Double(token.value) / Double(Token.fractional.precision)
            balances[tokenId] = tokenAmount
        }
        
        return balances
    }
    
    // MARK: - Trading
    
    func buyToken(tokenId: String, usdcAmount: Double, currentPrice: Double) async throws {
        // Check if we have enough USDC
        guard currentUsdcBalance.USDC >= usdcAmount else {
            throw AppError(message: "Insufficient USDC balance")
        }
        
        // Calculate tokens received
        let tokensReceived = usdcAmount / currentPrice
        
        // Deduct USDC
        currentUsdcBalance = Usdc(usdc: currentUsdcBalance.USDC - usdcAmount)
        
        // Add tokens
        let currentBalance = currentTokenBalances[tokenId] ?? .zero
        currentTokenBalances[tokenId] = Token(units: currentBalance.units.doubleValue + tokensReceived)
        
        print("💰 UserService: Bought \(String(format: "%.2f", tokensReceived)) \(tokenId) for $\(String(format: "%.2f", usdcAmount))")
        print("   New USDC balance: $\(String(format: "%.2f", currentUsdcBalance.USDC))")
        print("   New \(tokenId) balance: \(String(format: "%.2f", currentTokenBalances[tokenId]?.units.doubleValue ?? 0))")
    }
    
    func sellToken(tokenId: String, amount: Double, currentPrice: Double) async throws {
        let currentBalance = currentTokenBalances[tokenId] ?? .zero
        
        // Check if we have enough tokens
        guard currentBalance.units.doubleValue >= amount else {
            throw AppError(message: "Insufficient token balance")
        }
        
        // Calculate USDC received
        let usdcReceived = amount * currentPrice
        
        // Add USDC
        currentUsdcBalance = Usdc(usdc: currentUsdcBalance.USDC + usdcReceived)
        
        // Deduct tokens
        currentTokenBalances[tokenId] = Token(units: currentBalance.units.doubleValue - amount)
        
        print("💰 UserService: Sold \(String(format: "%.2f", amount)) \(tokenId) for $\(String(format: "%.2f", usdcReceived))")
        print("   New USDC balance: $\(String(format: "%.2f", currentUsdcBalance.USDC))")
        print("   New \(tokenId) balance: \(String(format: "%.2f", currentTokenBalances[tokenId]?.units.doubleValue ?? 0))")
    }
    
    func getCurrentPrice(for tokenId: String) async -> Double {
        // First check if we have a cached price from Helius
        if let cachedPrice = tokenPrices[tokenId] {
            return cachedPrice
        }
        
        return 0.0
    }
    
    // MARK: - Total Balance
    
    func getTotalBalance() async -> Usdc {
        var totalUsdc = currentUsdcBalance
        
        // Add SOL balance value
        let solAmount = currentSolanaBalance.SOL
        if solAmount > 0 {
            let solPrice = await getCurrentPrice(for: "So11111111111111111111111111111111111111112")
            let solValue = solAmount * solPrice
            totalUsdc = totalUsdc + Usdc(usdc: solValue)
        }
        
        // Add value of all tokens using current market prices
        for (tokenMint, tokenBalance) in currentTokenBalances {
            let price = await getCurrentPrice(for: tokenMint)
            let amount = tokenBalance.units.doubleValue
            
            // Skip if no price or zero balance
            guard price > 0, amount > 0 else { continue }
            
            let tokenValue = amount * price
            totalUsdc = totalUsdc + Usdc(usdc: tokenValue)
        }
        
        return totalUsdc
    }
    
    // MARK: - Token Holdings
    
    func getTokenHoldings() async -> [(address: String, symbol: String, name: String, decimals: Int, imageURL: String?, balance: Double, price: Double, priceChange: Double)] {
        var holdings: [(address: String, symbol: String, name: String, decimals: Int, imageURL: String?, balance: Double, price: Double, priceChange: Double)] = []
        
        // ✅ Add SOL balance first (native token) - always show even if 0
        let solMint = "So11111111111111111111111111111111111111112"
        let solBalance = currentSolanaBalance.SOL
        let solPrice = await getCurrentPrice(for: solMint)
        
        holdings.append((
            address: solMint,
            symbol: "SOL",
            name: "Solana",
            decimals: 9,
            imageURL: "https://raw.githubusercontent.com/solana-labs/token-list/main/assets/mainnet/So11111111111111111111111111111111111111112/logo.png",
            balance: solBalance,
            price: solPrice,
            priceChange: 0.0 // TODO: Get real price change for SOL
        ))
        
        // ✅ Add USDC balance - always show even if 0
        let usdcMint = "EPjFWdd5AufqSSqeM2qN1xzybapC8G4wEGGkZwyTDt1v"
        let usdcBalance = currentUsdcBalance.USDC
        
        holdings.append((
            address: usdcMint,
            symbol: "USDC",
            name: "USD Coin",
            decimals: 6,
            imageURL: "https://raw.githubusercontent.com/solana-labs/token-list/main/assets/mainnet/EPjFWdd5AufqSSqeM2qN1xzybapC8G4wEGGkZwyTDt1v/logo.png",
            balance: usdcBalance,
            price: 1.0, // USDC is always $1
            priceChange: 0.0
        ))
        
        // Add other SPL token balances (excluding USDC since we already added it)
        for (tokenMint, tokenBalance) in currentTokenBalances {
            // Skip USDC since we already added it
            if tokenMint == usdcMint {
                continue
            }
            
            guard let metadata = tokenMetadata[tokenMint],
                  let price = tokenPrices[tokenMint] else {
                continue
            }
            
            let balance = tokenBalance.units.doubleValue
            guard balance > 0 else { continue }
            
            holdings.append((
                address: tokenMint,
                symbol: metadata.symbol,
                name: metadata.name,
                decimals: metadata.decimals,
                imageURL: metadata.imageURL,
                balance: balance,
                price: price,
                priceChange: metadata.priceChange24h
            ))
        }
        
        // Sort by value (highest first)
        holdings.sort { $0.balance * $0.price > $1.balance * $1.price }
        
        return holdings
    }
    
    // MARK: - Methods
    
    func setup() async throws {
        print("👤 UserService: Setting up...")
        
        // Check if wallet exists
        guard await walletService.hasWallet() else {
            print("👤 UserService: No wallet found, showing zero balances")
            await setEmptyBalances()
            return
        }
        
        print("👤 UserService: Wallet found, fetching real balances")
        await refreshBalances()
        
        // Sync transactions in BACKGROUND - don't block app launch
        // Processed transactions are cached, so History screen loads instantly
        Task {
            do {
                let walletAddress = try await walletService.getPublicKey()
                
                if let initTimestamp = await walletService.getInitializationTimestamp() {
                    print("📜 UserService: Syncing transaction history (background)...")
                    try await transactionHistoryService.fetchNewTransactions(
                        walletAddress: walletAddress,
                        initTimestamp: initTimestamp
                    )
                    
                    let txCount = await transactionHistoryService.getTransactionCount()
                    print("✅ UserService: Transaction history synced (\(txCount) total transactions)")
                    
                    // Submit all historical tokens for indexing
                    await submitHistoricalTokensForIndexing()
                    
                    // Start polling for new transactions
                    await transactionHistoryService.startPolling(walletAddress: walletAddress)
                }
            } catch {
                print("⚠️ UserService: Failed to sync transactions: \(error)")
            }
        }
        
        // Start auto-refresh every 5 seconds
        startAutoRefresh()
    }
    
    func startAutoRefresh() {
        // Cancel existing task if any
        refreshTask?.cancel()
        
        print("🔄 UserService: Starting auto-refresh (every 5 seconds)")
        
        refreshTask = Task { [weak self] in
            while !Task.isCancelled {
                try? await Task.sleep(for: .seconds(5))
                
                guard !Task.isCancelled else { break }
                
                // Refresh balances
                await self?.refreshBalances()
                
                // Update prices from Jupiter (real-time!)
                await self?.updatePricesFromJupiter()
            }
        }
    }
    
    /// Fetch fresh prices from Jupiter for all held tokens
    private func updatePricesFromJupiter() async {
        
        // Get all token mints we currently hold (SOL + tokens)
        var mints: [String] = ["So11111111111111111111111111111111111111112"] // Always include SOL
        mints.append(contentsOf: currentTokenBalances.keys)
        
        guard !mints.isEmpty else { return }
        
        // Fetch fresh prices from Jupiter (batch API - more efficient!)
        do {
            let freshPrices = try await jupiterService.getTokenPrices(mints: mints)
            
            // Update cached prices
            for (mint, price) in freshPrices {
                tokenPrices[mint] = price
            }
            
            print("💸 Updated \(freshPrices.count) token prices from Jupiter")
        } catch {
            print("⚠️ Failed to update prices from Jupiter: \(error)")
        }
    }
    
    func stopAutoRefresh() {
        print("⏸️ UserService: Stopping auto-refresh")
        refreshTask?.cancel()
        refreshTask = nil
        
        // Also stop transaction polling
        Task {
            await transactionHistoryService.stopPolling()
        }
    }
    
    func forceRefreshBalances() async {
        print("🔄 UserService: Force refreshing balances...")
        // Trigger balance refresh by restarting auto-refresh
        // This will fetch fresh balances immediately
        stopAutoRefresh()
        startAutoRefresh()
    }
    
    func getPublicKey() async throws -> String {
        return try await walletService.getPublicKey()
    }
    
    func refreshBalances() async {
        print("👤 UserService: Refreshing balances from chain...")
        
        do {
            // Get wallet address
            let walletAddress = try await walletService.getPublicKey()
            print("   Wallet: \(walletAddress)")
            
            // Fetch all assets using Helius searchAssets (primary method)
            let response = try await heliusService.searchAssets(
                walletAddress: walletAddress,
                tokenType: "fungible",
                showZeroBalance: false
            )
            
            // Update SOL balance and price
            if let nativeBalance = response.result.nativeBalance {
                let solAmount = Double(nativeBalance.lamports) / 1_000_000_000.0 // lamports to SOL
                currentSolanaBalance = Sol(sol: solAmount)
                
                // Store SOL price
                let solPrice = nativeBalance.price_per_sol
                tokenPrices["So11111111111111111111111111111111111111112"] = solPrice
                
                let solValue = solAmount * solPrice
                print("   SOL: \(solAmount) @ $\(solPrice) = $\(solValue)")
            }
            
            // Update token balances
            var newTokenBalances: [String: Token] = [:]
            var usdcBalance: Double = 0.0
            var skippedTokensCount = 0
            
            for item in response.result.items {
                guard let tokenInfo = item.token_info,
                      let balance = tokenInfo.balance,
                      let decimals = tokenInfo.decimals else {
                    continue
                }
                
                // Get token address (mint)
                let tokenAddress = item.id
                
                // Check if this is USDC (EPjFWdd5AufqSSqeM2qN1xzybapC8G4wEGGkZwyTDt1v)
                if tokenAddress == "EPjFWdd5AufqSSqeM2qN1xzybapC8G4wEGGkZwyTDt1v" {
                    // USDC always included
                    let actualBalance = Double(balance) / pow(10.0, Double(decimals))
                    usdcBalance = actualBalance
                    print("   USDC: $\(actualBalance)")
                    continue
                }
                
                // Check if token is Jupiter-verified
                let isVerified = await jupiterService.isTokenVerified(mint: tokenAddress)
                guard isVerified else {
                    skippedTokensCount += 1
                    if let symbol = tokenInfo.symbol {
                        print("   ⏭️  Skipping \(symbol) (\(tokenAddress)): Not Jupiter-verified")
                    } else {
                        print("   ⏭️  Skipping \(tokenAddress): Not Jupiter-verified")
                    }
                    continue
                }
                
                // Skip tokens without price info
                guard let priceInfo = tokenInfo.price_info,
                      let pricePerToken = priceInfo.price_per_token,
                      pricePerToken > 0 else {
                    skippedTokensCount += 1
                    if let symbol = tokenInfo.symbol {
                        print("   ⚠️ Skipping \(symbol) (\(tokenAddress)): No price info")
                    } else {
                        print("   ⚠️ Skipping token \(tokenAddress): No price info")
                    }
                    continue
                }
                
                // Calculate actual balance (adjust for decimals)
                let actualBalance = Double(balance) / pow(10.0, Double(decimals))
                
                // Store token and its price
                newTokenBalances[tokenAddress] = Token(units: actualBalance)
                tokenPrices[tokenAddress] = pricePerToken
                
                // Store token metadata
                let symbol = tokenInfo.symbol ?? "UNKNOWN"
                let name = item.content?.metadata?.name ?? symbol
                let imageURL = item.content?.links?.image
                // Note: Helius doesn't provide 24h price change, defaulting to 0.0
                let priceChange = 0.0
                
                tokenMetadata[tokenAddress] = TokenHoldingMetadata(
                    symbol: symbol,
                    name: name,
                    decimals: decimals,
                    imageURL: imageURL,
                    priceChange24h: priceChange
                )
                
                let totalValue = actualBalance * pricePerToken
                print("   \(symbol): \(actualBalance) @ $\(pricePerToken) = $\(totalValue)")
            }
            
            if skippedTokensCount > 0 {
                print("   ⚠️ Skipped \(skippedTokensCount) token(s) without price info")
            }
            
            // Submit new tokens to backend for price indexing
            await submitTokensForIndexing(response: response)
            
            // Update state
            currentUsdcBalance = Usdc(usdc: usdcBalance)
            currentTokenBalances = newTokenBalances
            
            // Publish updated balances
            await solanaBalancePublisher.publish(currentSolanaBalance)
            await usdcBalancePublisher.publish(currentUsdcBalance)
            await tokenBalancesPublisher.publish(currentTokenBalances)
            
            print("✅ UserService: Balances refreshed - SOL: \(currentSolanaBalance.SOL), USDC: $\(currentUsdcBalance.USDC), Tokens: \(currentTokenBalances.count)")
            
        } catch {
            print("❌ UserService: Failed to refresh balances: \(error)")
            print("   Falling back to mock data")
            await setMockBalances()
        }
    }
    
    // MARK: - Private Methods
    
    /// Submit all tokens from transaction history for price indexing
    /// This should be called after transaction history is synced
    /// Ensures we have price data for ALL tokens user ever held, not just current holdings
    private func submitHistoricalTokensForIndexing() async {
        print("📊 UserService: Submitting historical tokens for indexing...")
        
        // ✅ USE CENTRALIZED VERIFIED TOKENS (includes historical)
        let verifiedTokens = await getVerifiedTokens(includeHistorical: true)
        
        guard !verifiedTokens.isEmpty else {
            print("   No verified tokens found")
            return
        }
        
        print("   Found \(verifiedTokens.count) verified tokens (current + historical)")
        
        var tokensToSubmit: [TokenIndexRequest] = []
        
        for tokenAddress in verifiedTokens {
            // Skip USDC (stablecoin, price = $1, doesn't need historical indexing)
            if tokenAddress == "EPjFWdd5AufqSSqeM2qN1xzybapC8G4wEGGkZwyTDt1v" {
                indexedTokens.insert(tokenAddress)
                continue
            }
            
            // Skip if already submitted
            if indexedTokens.contains(tokenAddress) {
                continue
            }
            
            // Add to batch (we'll get metadata from backend if needed)
            tokensToSubmit.append(TokenIndexRequest(
                address: tokenAddress,
                symbol: nil, // Backend will fetch if needed
                name: nil
            ))
        }
        
        guard !tokensToSubmit.isEmpty else {
            print("   ✅ All historical tokens already indexed")
            return
        }
        
        print("   📦 Submitting \(tokensToSubmit.count) verified tokens to backend:")
        for token in tokensToSubmit {
            print("      • \(String(token.address.prefix(8))...)  (\(token.symbol ?? "unknown"))")
        }
        
        // Submit to backend
        do {
            let result = try await orbBackendService.addTokensBatch(tokens: tokensToSubmit)
            print("✅ UserService: Submitted \(tokensToSubmit.count) historical tokens")
            print("   Accepted: \(result.data.accepted) (new)")
            print("   Skipped: \(result.data.skipped) (already indexed/queued)")
            print("   Rejected: \(result.data.rejected) (errors)")
            print("   Queue: \(result.queue.length) tokens")
            
            // Mark all submitted tokens as indexed optimistically
            for token in tokensToSubmit {
                indexedTokens.insert(token.address)
            }
            
            // Log skipped tokens (already indexed or in queue - keep in indexedTokens)
            if let skipped = result.skipped, !skipped.isEmpty {
                for token in skipped {
                    print("   ⏭️  \(String(token.address.prefix(8))...): \(token.reason)")
                }
            }
            
            // Remove rejected tokens from indexed set so they can be retried
            if let rejected = result.rejected, !rejected.isEmpty {
                for token in rejected {
                    indexedTokens.remove(token.address)
                    print("   ❌ \(String(token.address.prefix(8))...): \(token.reason)")
                }
            }
            
        } catch {
            print("⚠️ UserService: Failed to submit historical tokens: \(error)")
            
            // Check if it's a timeout error
            let nsError = error as NSError
            if nsError.domain == NSURLErrorDomain && nsError.code == NSURLErrorTimedOut {
                print("   ⏰ Backend timeout (cold start?) - will retry later")
                // Don't mark as indexed so we can retry
            } else {
                print("   Error domain: \(nsError.domain), code: \(nsError.code)")
            }
        }
    }
    
    /// Submit currently held tokens for price indexing
    /// This is called during balance refresh to catch newly acquired tokens
    /// Note: Historical tokens (from transaction history) are submitted separately
    /// via submitHistoricalTokensForIndexing()
    private func submitTokensForIndexing(response: HeliusSearchAssetsResponse) async {
        // ✅ USE CENTRALIZED VERIFIED TOKENS (current holdings only)
        let verifiedTokens = await getVerifiedTokens(includeHistorical: false)
        
        var tokensToSubmit: [TokenIndexRequest] = []
        
        let usdcMint = "EPjFWdd5AufqSSqeM2qN1xzybapC8G4wEGGkZwyTDt1v"
        
        for tokenAddress in verifiedTokens {
            // Skip USDC (stablecoin, price = $1, doesn't need indexing)
            if tokenAddress == usdcMint {
                indexedTokens.insert(tokenAddress)
                continue
            }
            
            // Skip if already indexed
            if indexedTokens.contains(tokenAddress) {
                continue
            }
            
            // Get token metadata from Helius response
            let metadata: (symbol: String?, name: String?)
            if tokenAddress == "So11111111111111111111111111111111111111112" {
                metadata = ("SOL", "Solana")
            } else if let item = response.result.items.first(where: { $0.id == tokenAddress }),
                      let tokenInfo = item.token_info {
                metadata = (tokenInfo.symbol, tokenInfo.name)
            } else {
                metadata = (nil, nil)
            }
            
            tokensToSubmit.append(TokenIndexRequest(
                address: tokenAddress,
                symbol: metadata.symbol,
                name: metadata.name
            ))
        }
        
        // Submit to backend if we have new tokens
        if !tokensToSubmit.isEmpty {
            print("   📦 Submitting \(tokensToSubmit.count) verified tokens to backend:")
            for token in tokensToSubmit {
                print("      • \(String(token.address.prefix(8))...)  (\(token.symbol ?? "unknown"))")
            }
            
            do {
                let result = try await orbBackendService.addTokensBatch(tokens: tokensToSubmit)
                print("📊 UserService: Submitted \(tokensToSubmit.count) tokens to backend")
                print("   Accepted: \(result.data.accepted) (new)")
                print("   Skipped: \(result.data.skipped) (already indexed/queued)")
                print("   Rejected: \(result.data.rejected) (errors)")
                print("   Queue: \(result.queue.length) tokens")
                
                // Mark all submitted tokens as indexed optimistically
                for token in tokensToSubmit {
                    indexedTokens.insert(token.address)
                }
                
                // Log skipped tokens (already indexed or in queue - keep in indexedTokens)
                if let skipped = result.skipped, !skipped.isEmpty {
                    for token in skipped {
                        print("   ⏭️  \(String(token.address.prefix(8))...): \(token.reason)")
                    }
                }
                
                // Remove rejected tokens so they can be retried next time
                if let rejected = result.rejected, !rejected.isEmpty {
                    for token in rejected {
                        indexedTokens.remove(token.address)
                        print("   ❌ \(String(token.address.prefix(8))...): \(token.reason)")
                    }
                }
                
            } catch {
                print("⚠️ UserService: Failed to submit tokens for indexing: \(error)")
                
                // Check if it's a timeout error
                let nsError = error as NSError
                if nsError.domain == NSURLErrorDomain && nsError.code == NSURLErrorTimedOut {
                    print("   ⏰ Backend timeout (cold start?) - will retry on next refresh")
                } else {
                    print("   Error domain: \(nsError.domain), code: \(nsError.code)")
                }
                
                // DON'T add to indexedTokens - will retry on next refresh
            }
        }
    }
    
    private func setEmptyBalances() async {
        // Zero balances for fresh install (no wallet)
        currentSolanaBalance = Sol(sol: 0.0)
        currentUsdcBalance = Usdc(usdc: 0.0)
        currentTokenBalances = [:]
        
        // Publish zero balances
        await solanaBalancePublisher.publish(currentSolanaBalance)
        await usdcBalancePublisher.publish(currentUsdcBalance)
        await tokenBalancesPublisher.publish(currentTokenBalances)
        
        print("👤 UserService: Zero balances set (no wallet)")
        print("   SOL: $0.00")
        print("   USDC: $0.00")
        print("   Tokens: 0")
    }
    
    private func setMockBalances() async {
        // Mock balances for testing (fallback when real fetch fails)
        currentSolanaBalance = Sol(sol: 5.5)
        currentUsdcBalance = Usdc(usdc: 10000.0)
        currentTokenBalances = [:] // No mock tokens
        
        // Publish mock balances
        await solanaBalancePublisher.publish(currentSolanaBalance)
        await usdcBalancePublisher.publish(currentUsdcBalance)
        await tokenBalancesPublisher.publish(currentTokenBalances)
        
        print("👤 UserService: Mock balances set (fallback)")
        print("   SOL: \(currentSolanaBalance.SOL)")
        print("   USDC: $\(currentUsdcBalance.USDC)")
        print("   Tokens: \(currentTokenBalances.count) tokens")
    }
}

// MARK: - Dependency

extension DependencyValues {
    var userService: UserService {
        get { self[UserServiceKey.self] }
        set { self[UserServiceKey.self] = newValue }
    }
}

private enum UserServiceKey: DependencyKey {
    static let liveValue: UserService = LiveUserService()
    
    static let testValue: UserService = { fatalError() }()
}

