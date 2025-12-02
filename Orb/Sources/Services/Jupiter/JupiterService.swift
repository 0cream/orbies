import Dependencies
import Foundation
import SolanaSwift

// MARK: - Protocol

protocol JupiterService: Actor {
    
    // MARK: - Setup
    
    func setup() async throws
    
    // MARK: - Prices
    
    /// Get current price for a token in USD
    func getTokenPrice(mint: String) async throws -> Double
    
    /// Get prices for multiple tokens at once
    func getTokenPrices(mints: [String]) async throws -> [String: Double]
    
    // MARK: - Swap Quotes
    
    /// Get best swap quote across all DEXs
    func getSwapQuote(
        inputMint: String,
        outputMint: String,
        amount: Double,
        slippageBps: Int
    ) async throws -> JupiterQuote
    
    /// Get multiple quote options
    func getSwapQuotes(
        inputMint: String,
        outputMint: String,
        amount: Double,
        slippageBps: Int
    ) async throws -> [JupiterQuote]
    
    // MARK: - Ultra API - Swap Orders
    
    /// Get a swap order from Jupiter Ultra API
    /// This returns a base64-encoded unsigned transaction to be signed and executed
    func getSwapOrder(
        inputMint: String,
        outputMint: String,
        amount: String,
        taker: String,
        slippageBps: Int
    ) async throws -> JupiterUltraOrder
    
    // MARK: - Swap Execution
    
    /// Execute a swap (requires wallet signing)
    func executeSwap(quote: JupiterQuote, userPublicKey: String) async throws -> String
    
    /// Sign an Ultra swap transaction
    /// - Parameter order: The Jupiter Ultra order containing the unsigned transaction
    /// - Returns: Signed transaction data (base58-encoded)
    func signUltraSwapTransaction(order: JupiterUltraOrder) async throws -> String
    
    // MARK: - Token Info
    
    /// Get all tradeable tokens on Jupiter
    func getAllTokens() async throws -> [JupiterToken]
    
    /// Search tokens by symbol or name
    func searchTokens(query: String) async throws -> [JupiterToken]
    
    /// Get all verified tokens list (~7k tokens)
    func getVerifiedTokens() async throws -> [JupiterVerifiedToken]
    
    /// Check if a token is verified
    func isTokenVerified(mint: String) async -> Bool
    
    /// Get token icon URL by mint address
    func getTokenIcon(mint: String) async -> String?
    
    /// Get top traded tokens in the last 24 hours
    func getTopTradedTokens(limit: Int) async throws -> [JupiterVerifiedToken]
    
    /// Get token decimals by mint address
    func getTokenDecimals(mint: String) async -> Int
}

// MARK: - Live Implementation

actor LiveJupiterService: JupiterService {
    
    // MARK: - Dependencies
    
    @Dependency(\.walletService)
    private var walletService: WalletService
    
    // MARK: - Properties
    
    private let quoteAPIBase = "https://quote-api.jup.ag/v6"
    private let priceAPIBase = "https://lite-api.jup.ag/price/v3"  // ✅ Fixed: v3 endpoint
    private let tokensAPIBase = "https://token.jup.ag"
    private let ultraAPIBase = "https://api.jup.ag/ultra/v1"
    private let jupiterAPIKey = "640324ae-9a9f-4270-94c9-6fda44e7fae7"
    
    // MARK: - State
    
    private var cachedTokens: [JupiterToken] = []
    private var cachedVerifiedTokens: [JupiterVerifiedToken] = []
    private var verifiedTokensSet: Set<String> = [] // For fast lookup
    private var cachedPrices: [String: CachedPrice] = [:]
    
    private struct CachedPrice {
        let price: Double
        let timestamp: Date
        
        var isStale: Bool {
            Date().timeIntervalSince(timestamp) > 60 // 1 minute
        }
    }
    
    // MARK: - Setup
    
    func setup() async throws {
        print("🪐 JupiterService: Starting setup...")
        print("   Quote API: \(quoteAPIBase)")
        print("   Price API: \(priceAPIBase)")
        
        // Prefetch verified tokens list (critical for filtering)
        do {
            let verifiedTokens = try await getVerifiedTokens()
            print("✅ JupiterService: Setup complete, \(verifiedTokens.count) verified tokens loaded")
        } catch {
            print("⚠️ JupiterService: Could not fetch verified tokens during setup: \(error)")
            print("   App will continue with SOL + USDC only until tokens list is fetched")
            // Don't throw - let the app continue with fallback behavior
        }
    }
    
    // MARK: - Prices
    
    func getTokenPrice(mint: String) async throws -> Double {
        // Check cache
        if let cached = cachedPrices[mint], !cached.isStale {
            return cached.price
        }
        
        // Fetch from API
        let url = URL(string: "\(priceAPIBase)?ids=\(mint)")!
        let (data, _) = try await URLSession.shared.data(from: url)
        let response = try JSONDecoder().decode(JupiterPriceResponse.self, from: data)
        
        guard let priceData = response[mint] else {
            throw JupiterServiceError.priceNotFound
        }
        
        // Cache it
        cachedPrices[mint] = CachedPrice(price: priceData.usdPrice, timestamp: Date())
        
        print("🪐 JupiterService: Price for \(mint): $\(priceData.usdPrice)")
        return priceData.usdPrice
    }
    
    func getTokenPrices(mints: [String]) async throws -> [String: Double] {
        let mintsString = mints.joined(separator: ",")
        let url = URL(string: "\(priceAPIBase)?ids=\(mintsString)")!
        let (data, _) = try await URLSession.shared.data(from: url)
        let response = try JSONDecoder().decode(JupiterPriceResponse.self, from: data)
        
        var prices: [String: Double] = [:]
        // v3 API: response is directly [mint: priceData], no "data" wrapper
        for (mint, priceData) in response {
            prices[mint] = priceData.usdPrice
            cachedPrices[mint] = CachedPrice(price: priceData.usdPrice, timestamp: Date())
        }
        
        print("🪐 JupiterService: Fetched prices for \(prices.count) tokens")
        return prices
    }
    
    // MARK: - Swap Quotes
    
    func getSwapQuote(
        inputMint: String,
        outputMint: String,
        amount: Double,
        slippageBps: Int = 50
    ) async throws -> JupiterQuote {
        let quotes = try await getSwapQuotes(
            inputMint: inputMint,
            outputMint: outputMint,
            amount: amount,
            slippageBps: slippageBps
        )
        
        guard let bestQuote = quotes.first else {
            throw JupiterServiceError.noQuotesAvailable
        }
        
        return bestQuote
    }
    
    func getSwapQuotes(
        inputMint: String,
        outputMint: String,
        amount: Double,
        slippageBps: Int = 50
    ) async throws -> [JupiterQuote] {
        // Convert amount to smallest unit (assuming 9 decimals for now)
        let amountInSmallestUnit = Int(amount * 1_000_000_000)
        
        let urlString = "\(quoteAPIBase)/quote?inputMint=\(inputMint)&outputMint=\(outputMint)&amount=\(amountInSmallestUnit)&slippageBps=\(slippageBps)"
        
        guard let url = URL(string: urlString) else {
            throw JupiterServiceError.invalidURL
        }
        
        let (data, _) = try await URLSession.shared.data(from: url)
        let response = try JSONDecoder().decode(JupiterQuoteResponse.self, from: data)
        
        // Convert to our model
        let quote = JupiterQuote(
            inputMint: response.inputMint,
            outputMint: response.outputMint,
            inAmount: response.inAmount,
            outAmount: response.outAmount,
            otherAmountThreshold: response.otherAmountThreshold,
            swapMode: response.swapMode,
            slippageBps: response.slippageBps,
            priceImpactPct: response.priceImpactPct,
            routePlan: response.routePlan
        )
        
        print("🪐 JupiterService: Got quote")
        print("   Input: \(amount) of \(inputMint)")
        print("   Output: ~\(Double(response.outAmount) ?? 0 / 1_000_000_000) of \(outputMint)")
        print("   Price Impact: \(response.priceImpactPct)%")
        
        return [quote]
    }
    
    // MARK: - Ultra API - Swap Orders
    
    func getSwapOrder(
        inputMint: String,
        outputMint: String,
        amount: String,
        taker: String,
        slippageBps: Int = 50
    ) async throws -> JupiterUltraOrder {
        // Build URL with query parameters
        var components = URLComponents(string: "\(ultraAPIBase)/order")!
        components.queryItems = [
            URLQueryItem(name: "inputMint", value: inputMint),
            URLQueryItem(name: "outputMint", value: outputMint),
            URLQueryItem(name: "amount", value: amount),
            URLQueryItem(name: "taker", value: taker),
            URLQueryItem(name: "slippageBps", value: String(slippageBps))
        ]
        
        guard let url = components.url else {
            throw JupiterServiceError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue(jupiterAPIKey, forHTTPHeaderField: "x-api-key")
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw JupiterServiceError.apiError("Invalid response")
        }
        
        guard httpResponse.statusCode == 200 else {
            let errorText = String(data: data, encoding: .utf8) ?? "Unknown error"
            throw JupiterServiceError.apiError("HTTP \(httpResponse.statusCode): \(errorText)")
        }
        
        let decoder = JSONDecoder()
        let order = try decoder.decode(JupiterUltraOrder.self, from: data)
        
        print("🪐 JupiterService: Got Ultra swap order")
        print("   Input: \(order.inAmount) of \(order.inputMint)")
        print("   Output: \(order.outAmount) of \(order.outputMint)")
        print("   Router: \(order.router)")
        if let priceImpact = order.priceImpact {
            print("   Price Impact: \(priceImpact)")
        }
        
        return order
    }
    
    // MARK: - Swap Execution
    
    func executeSwap(quote: JupiterQuote, userPublicKey: String) async throws -> String {
        // This requires wallet signing - not implemented yet
        throw JupiterServiceError.notImplemented
    }
    
    func signUltraSwapTransaction(order: JupiterUltraOrder) async throws -> String {
        print("🪐 JupiterService: Signing Ultra swap transaction...")
        
        // Check if transaction is present
        guard let transactionBase64 = order.transaction, !transactionBase64.isEmpty else {
            if let error = order.error ?? order.errorMessage {
                throw JupiterServiceError.apiError("Transaction error: \(error)")
            }
            throw JupiterServiceError.apiError("No transaction returned from Jupiter")
        }
        
        // Decode base64 transaction
        guard let transactionData = Data(base64Encoded: transactionBase64) else {
            throw JupiterServiceError.apiError("Failed to decode transaction from base64")
        }
        
        print("   Transaction size: \(transactionData.count) bytes")
        
        // Sign transaction via WalletService
        let signedTransactionData = try await walletService.signTransaction(transactionData: transactionData)
        
        // Encode to base58 for RPC submission
        let signedTransactionBase58 = Base58.encode(signedTransactionData.bytes)
        
        print("✅ JupiterService: Transaction signed!")
        
        return signedTransactionBase58
    }
    
    // MARK: - Token Info
    
    func getAllTokens() async throws -> [JupiterToken] {
        // Return cached if available
        if !cachedTokens.isEmpty {
            return cachedTokens
        }
        
        let url = URL(string: "\(tokensAPIBase)/strict")!
        let (data, _) = try await URLSession.shared.data(from: url)
        let tokens = try JSONDecoder().decode([JupiterToken].self, from: data)
        
        cachedTokens = tokens
        print("🪐 JupiterService: Loaded \(tokens.count) tokens")
        
        return tokens
    }
    
    func searchTokens(query: String) async throws -> [JupiterToken] {
        let allTokens = try await getAllTokens()
        let lowercaseQuery = query.lowercased()
        
        return allTokens.filter { token in
            token.symbol.lowercased().contains(lowercaseQuery) ||
            token.name.lowercased().contains(lowercaseQuery) ||
            token.address.lowercased().contains(lowercaseQuery)
        }
    }
    
    func getVerifiedTokens() async throws -> [JupiterVerifiedToken] {
        // Return cached if available
        if !cachedVerifiedTokens.isEmpty {
            print("🪐 JupiterService: Using cached verified tokens (\(cachedVerifiedTokens.count))")
            return cachedVerifiedTokens
        }
        
        print("🪐 JupiterService: Fetching verified tokens list...")
        
        // Jupiter's verified token list endpoint with query parameter
        let url = URL(string: "https://lite-api.jup.ag/tokens/v2/tag?query=verified")!
        
        do {
            let (data, response) = try await URLSession.shared.data(from: url)
            
            // Check HTTP response
            if let httpResponse = response as? HTTPURLResponse {
                print("   HTTP Status: \(httpResponse.statusCode)")
                if httpResponse.statusCode != 200 {
                    let responseText = String(data: data, encoding: .utf8) ?? "Unable to decode response"
                    print("   Response: \(responseText.prefix(500))...")
                    throw JupiterServiceError.apiError("HTTP \(httpResponse.statusCode)")
                }
            }
            
            // Parse JSON manually to handle edge cases
            guard let jsonArray = try? JSONSerialization.jsonObject(with: data) as? [[String: Any]] else {
                throw JupiterServiceError.apiError("Invalid JSON response")
            }
            
            print("   Received \(jsonArray.count) tokens, parsing...")
            
            // Filter to only verified tokens and extract mint addresses
            var verifiedMints: Set<String> = []
            var parsedTokens: [JupiterVerifiedToken] = []
            
            for tokenDict in jsonArray {
                // Check if verified
                guard let isVerified = tokenDict["isVerified"] as? Bool, isVerified == true else {
                    continue
                }
                
                // Get required fields
                guard let id = tokenDict["id"] as? String,
                      let name = tokenDict["name"] as? String,
                      let symbol = tokenDict["symbol"] as? String else {
                    continue
                }
                
                verifiedMints.insert(id)
                
                // Create minimal token object (we don't need all the metadata)
                let token = JupiterVerifiedToken(
                    id: id,
                    name: name,
                    symbol: symbol,
                    icon: tokenDict["icon"] as? String,
                    decimals: tokenDict["decimals"] as? Int ?? 9,
                    twitter: nil,
                    telegram: nil,
                    website: nil,
                    dev: nil,
                    circSupply: nil,
                    totalSupply: nil,
                    tokenProgram: nil,
                    launchpad: nil,
                    partnerConfig: nil,
                    graduatedPool: nil,
                    graduatedAt: nil,
                    holderCount: nil,
                    fdv: nil,
                    mcap: nil,
                    usdPrice: nil,
                    priceBlockId: nil,
                    liquidity: nil,
                    stats5m: nil,
                    stats1h: nil,
                    stats6h: nil,
                    stats24h: nil,
                    firstPool: nil,
                    audit: nil,
                    organicScore: nil,
                    organicScoreLabel: nil,
                    isVerified: true,
                    cexes: nil,
                    tags: tokenDict["tags"] as? [String],
                    updatedAt: nil
                )
                
                parsedTokens.append(token)
            }
            
            let verifiedOnly = parsedTokens
            
            // Cache the list
            cachedVerifiedTokens = verifiedOnly
            verifiedTokensSet = Set(verifiedOnly.map { $0.id })
            
            print("✅ JupiterService: Loaded \(verifiedOnly.count) verified tokens")
            
            return verifiedOnly
        } catch let decodingError as DecodingError {
            print("❌ JupiterService: Decoding error: \(decodingError)")
            throw JupiterServiceError.apiError("Failed to decode tokens: \(decodingError)")
        } catch {
            print("❌ JupiterService: Network error: \(error)")
            throw error
        }
    }
    
    func isTokenVerified(mint: String) async -> Bool {
        // Hardcoded always-verified tokens (SOL, USDC) as fallback
        let alwaysVerified = [
            "So11111111111111111111111111111111111111112", // SOL
            "EPjFWdd5AufqSSqeM2qN1xzybapC8G4wEGGkZwyTDt1v" // USDC
        ]
        
        if alwaysVerified.contains(mint) {
            return true
        }
        
        // Ensure we have the verified list
        if verifiedTokensSet.isEmpty {
            do {
                _ = try await getVerifiedTokens()
            } catch {
                print("⚠️ JupiterService: Failed to fetch verified tokens: \(error)")
                print("   Falling back to SOL + USDC only")
                return false // Only SOL and USDC will pass (from hardcoded list above)
            }
        }
        
        return verifiedTokensSet.contains(mint)
    }
    
    func getTokenIcon(mint: String) async -> String? {
        // Ensure tokens are loaded
        if cachedVerifiedTokens.isEmpty {
            do {
                _ = try await getVerifiedTokens()
            } catch {
                print("⚠️ JupiterService: Failed to get token icon - \(error.localizedDescription)")
                return nil
            }
        }
        
        // Find token by mint address (id)
        return cachedVerifiedTokens.first(where: { $0.id == mint })?.icon
    }
    
    func getTokenDecimals(mint: String) async -> Int {
        // Hardcoded common tokens for quick lookup
        let commonDecimals: [String: Int] = [
            "So11111111111111111111111111111111111111112": 9,  // SOL
            "EPjFWdd5AufqSSqeM2qN1xzybapC8G4wEGGkZwyTDt1v": 6,  // USDC
            "Es9vMFrzaCERmJfrF4H2FYD4KCoNkY11McCe8BenwNYB": 6,  // USDT
        ]
        
        if let decimals = commonDecimals[mint] {
            return decimals
        }
        
        // Check cached verified tokens
        if cachedVerifiedTokens.isEmpty {
            do {
                _ = try await getVerifiedTokens()
            } catch {
                print("⚠️ JupiterService: Failed to fetch token decimals, defaulting to 6")
                return 6
            }
        }
        
        if let token = cachedVerifiedTokens.first(where: { $0.id == mint }) {
            return token.decimals
        }
        
        // Default to 6 if not found
        print("⚠️ JupiterService: Token decimals not found for \(mint), defaulting to 6")
        return 6
    }
    
    func getTopTradedTokens(limit: Int) async throws -> [JupiterVerifiedToken] {
        print("🪐 JupiterService: Fetching top \(limit) traded tokens...")
        
        let url = URL(string: "https://lite-api.jup.ag/tokens/v2/toptraded/24h?limit=\(limit)")!
        
        do {
            let (data, response) = try await URLSession.shared.data(from: url)
            
            // Check HTTP response
            if let httpResponse = response as? HTTPURLResponse {
                print("   HTTP Status: \(httpResponse.statusCode)")
                if httpResponse.statusCode != 200 {
                    let responseText = String(data: data, encoding: .utf8) ?? "Unable to decode response"
                    print("   Response: \(responseText.prefix(500))...")
                    throw JupiterServiceError.apiError("HTTP \(httpResponse.statusCode)")
                }
            }
            
            // Parse JSON manually to handle edge cases (like getVerifiedTokens)
            guard let jsonArray = try? JSONSerialization.jsonObject(with: data) as? [[String: Any]] else {
                throw JupiterServiceError.apiError("Invalid JSON response")
            }
            
            print("   Received \(jsonArray.count) tokens, parsing...")
            
            var topTokens: [JupiterVerifiedToken] = []
            
            for tokenDict in jsonArray {
                // Get required fields
                guard let id = tokenDict["id"] as? String,
                      let name = tokenDict["name"] as? String,
                      let symbol = tokenDict["symbol"] as? String else {
                    continue
                }
                
                // Helper to parse token stats
                func parseStats(_ dict: [String: Any]?) -> JupiterTokenStats? {
                    guard let dict = dict else { return nil }
                    return JupiterTokenStats(
                        priceChange: dict["priceChange"] as? Double,
                        holderChange: dict["holderChange"] as? Int,
                        liquidityChange: dict["liquidityChange"] as? Double,
                        volumeChange: dict["volumeChange"] as? Double,
                        buyVolume: dict["buyVolume"] as? Double,
                        sellVolume: dict["sellVolume"] as? Double,
                        buyOrganicVolume: dict["buyOrganicVolume"] as? Double,
                        sellOrganicVolume: dict["sellOrganicVolume"] as? Double,
                        numBuys: dict["numBuys"] as? Int,
                        numSells: dict["numSells"] as? Int,
                        numTraders: dict["numTraders"] as? Int,
                        numOrganicBuyers: dict["numOrganicBuyers"] as? Int,
                        numNetBuyers: dict["numNetBuyers"] as? Int
                    )
                }
                
                // Parse all stats
                let stats5m = parseStats(tokenDict["stats5m"] as? [String: Any])
                let stats1h = parseStats(tokenDict["stats1h"] as? [String: Any])
                let stats6h = parseStats(tokenDict["stats6h"] as? [String: Any])
                let stats24h = parseStats(tokenDict["stats24h"] as? [String: Any])
                
                // Parse firstPool
                var firstPool: JupiterFirstPool? = nil
                if let firstPoolDict = tokenDict["firstPool"] as? [String: Any],
                   let poolId = firstPoolDict["id"] as? String,
                   let createdAt = firstPoolDict["createdAt"] as? String {
                    firstPool = JupiterFirstPool(id: poolId, createdAt: createdAt)
                }
                
                // Parse audit
                var audit: JupiterAudit? = nil
                if let auditDict = tokenDict["audit"] as? [String: Any] {
                    audit = JupiterAudit(
                        isSus: auditDict["isSus"] as? Bool,
                        mintAuthorityDisabled: auditDict["mintAuthorityDisabled"] as? Bool,
                        freezeAuthorityDisabled: auditDict["freezeAuthorityDisabled"] as? Bool,
                        topHoldersPercentage: auditDict["topHoldersPercentage"] as? Double,
                        devBalancePercentage: auditDict["devBalancePercentage"] as? Double,
                        devMigrations: auditDict["devMigrations"] as? Int
                    )
                }
                
                // Create token object
                let token = JupiterVerifiedToken(
                    id: id,
                    name: name,
                    symbol: symbol,
                    icon: tokenDict["icon"] as? String,
                    decimals: tokenDict["decimals"] as? Int ?? 6,
                    twitter: tokenDict["twitter"] as? String,
                    telegram: tokenDict["telegram"] as? String,
                    website: tokenDict["website"] as? String,
                    dev: tokenDict["dev"] as? String,
                    circSupply: tokenDict["circSupply"] as? Double,
                    totalSupply: tokenDict["totalSupply"] as? Double,
                    tokenProgram: tokenDict["tokenProgram"] as? String,
                    launchpad: tokenDict["launchpad"] as? String,
                    partnerConfig: tokenDict["partnerConfig"] as? String,
                    graduatedPool: tokenDict["graduatedPool"] as? String,
                    graduatedAt: tokenDict["graduatedAt"] as? String,
                    holderCount: tokenDict["holderCount"] as? Int,
                    fdv: tokenDict["fdv"] as? Double,
                    mcap: tokenDict["mcap"] as? Double,
                    usdPrice: tokenDict["usdPrice"] as? Double,
                    priceBlockId: tokenDict["priceBlockId"] as? Int,
                    liquidity: tokenDict["liquidity"] as? Double,
                    stats5m: stats5m,
                    stats1h: stats1h,
                    stats6h: stats6h,
                    stats24h: stats24h,
                    firstPool: firstPool,
                    audit: audit,
                    organicScore: tokenDict["organicScore"] as? Double,
                    organicScoreLabel: tokenDict["organicScoreLabel"] as? String,
                    isVerified: tokenDict["isVerified"] as? Bool,
                    cexes: tokenDict["cexes"] as? [String],
                    tags: tokenDict["tags"] as? [String],
                    updatedAt: tokenDict["updatedAt"] as? String
                )
                
                topTokens.append(token)
            }
            
            print("✅ JupiterService: Loaded \(topTokens.count) top traded tokens")
            
            return topTokens
        } catch let decodingError as DecodingError {
            print("❌ JupiterService: Decoding error: \(decodingError)")
            throw JupiterServiceError.apiError("Failed to decode tokens: \(decodingError)")
        } catch {
            print("❌ JupiterService: Network error: \(error)")
            throw error
        }
    }
}

// MARK: - Models

struct JupiterQuote: Codable, Equatable {
    let inputMint: String
    let outputMint: String
    let inAmount: String
    let outAmount: String
    let otherAmountThreshold: String
    let swapMode: String
    let slippageBps: Int
    let priceImpactPct: Double
    let routePlan: [JupiterRouteStep]
    
    var inputAmount: Double {
        Double(inAmount) ?? 0
    }
    
    var outputAmount: Double {
        Double(outAmount) ?? 0
    }
}

struct JupiterRouteStep: Codable, Equatable {
    let swapInfo: JupiterSwapInfo
}

struct JupiterSwapInfo: Codable, Equatable {
    let ammKey: String
    let label: String?
    let inputMint: String
    let outputMint: String
    let inAmount: String
    let outAmount: String
    let feeAmount: String
    let feeMint: String
}

struct JupiterToken: Codable, Identifiable {
    let address: String
    let symbol: String
    let name: String
    let decimals: Int
    let logoURI: String?
    let tags: [String]?
    
    var id: String { address }
}

struct JupiterVerifiedToken: Codable, Identifiable, Sendable {
    let id: String                    // Token mint address
    let name: String
    let symbol: String
    let icon: String?
    let decimals: Int
    let twitter: String?
    let telegram: String?
    let website: String?
    let dev: String?
    let circSupply: Double?
    let totalSupply: Double?
    let tokenProgram: String?
    let launchpad: String?
    let partnerConfig: String?
    let graduatedPool: String?
    let graduatedAt: String?
    let holderCount: Int?
    let fdv: Double?
    let mcap: Double?
    let usdPrice: Double?
    let priceBlockId: Int?
    let liquidity: Double?
    let stats5m: JupiterTokenStats?
    let stats1h: JupiterTokenStats?
    let stats6h: JupiterTokenStats?
    let stats24h: JupiterTokenStats?
    let firstPool: JupiterFirstPool?
    let audit: JupiterAudit?
    let organicScore: Double?
    let organicScoreLabel: String?
    let isVerified: Bool?
    let cexes: [String]?
    let tags: [String]?
    let updatedAt: String?
}

struct JupiterTokenStats: Codable, Sendable {
    let priceChange: Double?
    let holderChange: Int?
    let liquidityChange: Double?
    let volumeChange: Double?
    let buyVolume: Double?
    let sellVolume: Double?
    let buyOrganicVolume: Double?
    let sellOrganicVolume: Double?
    let numBuys: Int?
    let numSells: Int?
    let numTraders: Int?
    let numOrganicBuyers: Int?
    let numNetBuyers: Int?
}

struct JupiterFirstPool: Codable, Sendable {
    let id: String
    let createdAt: String
}

struct JupiterAudit: Codable, Sendable {
    let isSus: Bool?
    let mintAuthorityDisabled: Bool?
    let freezeAuthorityDisabled: Bool?
    let topHoldersPercentage: Double?
    let devBalancePercentage: Double?
    let devMigrations: Int?
}

// MARK: - API Response Models

// v3 API response: direct dictionary without "data" wrapper
typealias JupiterPriceResponse = [String: JupiterPriceData]

struct JupiterPriceData: Codable {
    let usdPrice: Double        // Changed from "price" to "usdPrice" in v3
    let blockId: Int?           // Optional: block height of price update
    let decimals: Int?          // Optional: token decimals
    let priceChange24h: Double? // Optional: 24h price change percentage
}

struct JupiterQuoteResponse: Codable {
    let inputMint: String
    let inAmount: String
    let outputMint: String
    let outAmount: String
    let otherAmountThreshold: String
    let swapMode: String
    let slippageBps: Int
    let priceImpactPct: Double
    let routePlan: [JupiterRouteStep]
}

// MARK: - Ultra API Models

struct JupiterUltraOrder: Codable, Equatable, Sendable {
    let mode: String
    let inputMint: String
    let outputMint: String
    let inAmount: String
    let outAmount: String
    let inUsdValue: Double?
    let outUsdValue: Double?
    let priceImpact: Double?
    let swapUsdValue: Double?
    let otherAmountThreshold: String
    let swapMode: String
    let slippageBps: Int
    let priceImpactPct: String
    let routePlan: [JupiterUltraRoutePlan]
    let referralAccount: String?
    let feeMint: String
    let feeBps: Int
    let platformFee: JupiterUltraPlatformFee
    let signatureFeeLamports: Int
    let signatureFeePayer: String?
    let prioritizationFeeLamports: Int
    let prioritizationFeePayer: String?
    let rentFeeLamports: Int
    let rentFeePayer: String?
    let swapType: String
    let router: String
    let transaction: String?
    let gasless: Bool
    let requestId: String
    let totalTime: Double
    let taker: String?
    let quoteId: String?
    let maker: String?
    let expireAt: String?
    let errorCode: Int?
    let errorMessage: String?
    let error: String?
    
    var inputAmountDouble: Double {
        Double(inAmount) ?? 0
    }
    
    var outputAmountDouble: Double {
        Double(outAmount) ?? 0
    }
}

struct JupiterUltraRoutePlan: Codable, Equatable, Sendable {
    let swapInfo: JupiterUltraSwapInfo
    let percent: Int
    let bps: Int
    let usdValue: Double?
}

struct JupiterUltraSwapInfo: Codable, Equatable, Sendable {
    let ammKey: String
    let label: String
    let inputMint: String
    let outputMint: String
    let inAmount: String
    let outAmount: String
    let feeAmount: String
    let feeMint: String
}

struct JupiterUltraPlatformFee: Codable, Equatable, Sendable {
    let amount: String?
    let feeBps: Int
}

// MARK: - Errors

enum JupiterServiceError: Error, LocalizedError {
    case notInitialized
    case invalidURL
    case priceNotFound
    case noQuotesAvailable
    case notImplemented
    case apiError(String)
    
    var errorDescription: String? {
        switch self {
        case .notInitialized:
            return "Jupiter service not initialized. Call setup() first."
        case .invalidURL:
            return "Invalid URL"
        case .priceNotFound:
            return "Price not found for token"
        case .noQuotesAvailable:
            return "No swap quotes available"
        case .notImplemented:
            return "Feature not yet implemented"
        case .apiError(let message):
            return "Jupiter API error: \(message)"
        }
    }
}

// MARK: - Dependency

extension DependencyValues {
    var jupiterService: JupiterService {
        get { self[JupiterServiceKey.self] }
        set { self[JupiterServiceKey.self] = newValue }
    }
}

private enum JupiterServiceKey: DependencyKey {
    static let liveValue: JupiterService = LiveJupiterService()
    static let testValue: JupiterService = { fatalError("JupiterService not mocked for tests") }()
}

