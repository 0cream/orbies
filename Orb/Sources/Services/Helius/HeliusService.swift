import Dependencies
import Foundation

// MARK: - Protocol

protocol HeliusService: Actor {
    
    // MARK: - Setup
    
    func setup() async throws
    
    // MARK: - Enhanced Balances (DAS API)
    
    /// **Primary method to fetch user balances**
    ///
    /// Use `searchAssets` with `tokenType: fungible` to get all SPL token balances
    /// with enriched metadata, USD prices, and native SOL balance.
    ///
    /// This is the recommended method for portfolio/balance fetching because:
    /// - Returns complete token balances with USD values
    /// - Includes native SOL balance + USD value
    /// - Provides metadata (logos, names, symbols)
    /// - Supports advanced filtering (compressed, burnt, frozen, etc.)
    /// - Better pagination support
    ///
    /// - Parameters:
    ///   - walletAddress: The Solana wallet address to fetch balances for
    ///   - tokenType: Filter by token type (default: `fungible` for SPL tokens)
    ///   - showZeroBalance: Include tokens with zero balance (default: false)
    /// - Returns: Array of `HeliusAsset` with complete balance and metadata
    func searchAssets(
        walletAddress: String,
        tokenType: String,
        showZeroBalance: Bool
    ) async throws -> HeliusSearchAssetsResponse
    
    /// Get enriched token balances with USD values
    ///
    /// Convenience wrapper around `searchAssets` that filters for fungible tokens only
    /// and converts to `HeliusTokenBalance` model.
    func getEnrichedBalances(walletAddress: String) async throws -> [HeliusTokenBalance]
    
    // MARK: - Token Metadata (DAS API)
    
    /// Get enriched token metadata
    func getTokenMetadata(mint: String) async throws -> HeliusTokenMetadata
    
    // MARK: - Enhanced Transactions
    
    /// **Get enhanced transaction history with human-readable decoded data**
    ///
    /// This is the primary method for fetching transaction history with full context.
    /// Uses Helius Enhanced Transactions API (REST, not RPC).
    ///
    /// Features:
    /// - Human-readable descriptions
    /// - Decoded instructions and events
    /// - Token transfers with full details
    /// - Swap events with routes
    /// - NFT sale/listing/bid events
    ///
    /// - Parameters:
    ///   - address: Wallet address to get transactions for
    ///   - before: Search backwards from this signature
    ///   - limit: Number of transactions (1-100)
    ///   - type: Filter by transaction type (SWAP, NFT_SALE, TRANSFER, etc.)
    ///   - source: Filter by source (JUPITER, MAGIC_EDEN, etc.)
    /// - Returns: Array of enhanced transactions with full details
    func getEnhancedTransactions(
        address: String,
        before: String?,
        limit: Int,
        type: String?,
        source: String?
    ) async throws -> [HeliusEnhancedTransaction]
    
    // MARK: - Priority Fees
    
    /// **Get optimal priority fee estimates for transactions**
    ///
    /// Calculate priority fees based on real-time network conditions.
    /// Essential for ensuring transactions get processed during network congestion.
    ///
    /// - Parameters:
    ///   - transaction: Base58/Base64 encoded transaction (optional)
    ///   - accountKeys: Array of account public keys (alternative to transaction)
    ///   - includeAllLevels: Return all fee levels (min, low, medium, high, veryHigh, unsafeMax)
    ///   - priorityLevel: Get specific level only
    /// - Returns: Priority fee estimate(s) in microlamports
    func getPriorityFeeEstimate(
        transaction: String?,
        accountKeys: [String]?,
        includeAllLevels: Bool
    ) async throws -> HeliusPriorityFeeResponse
    
    // MARK: - Transaction History
    
    /// Get transactions for address with advanced filtering and sorting
    /// - Parameters:
    ///   - address: Solana account address
    ///   - limit: Maximum number of transactions (1-1000 for signatures, 1-100 for full)
    ///   - sortOrder: "asc" for oldest first, "desc" for newest first
    ///   - transactionDetails: "signatures" or "full"
    /// - Returns: Transaction data and pagination info
    func getTransactionsForAddress(
        address: String,
        limit: Int,
        sortOrder: String,
        transactionDetails: String
    ) async throws -> HeliusTransactionsForAddressResponse
    
    /// Get the first (oldest) transaction for an address
    /// - Parameter address: Solana account address
    /// - Returns: First transaction signature with timestamp, or nil if no transactions
    func getFirstTransaction(address: String) async throws -> HeliusTransactionSignature?
    
    // MARK: - Webhooks (for real-time updates)
    
    /// Create webhook for balance changes
    func createBalanceWebhook(walletAddress: String, webhookURL: String) async throws -> String
    
    // MARK: - Transaction Submission
    
    /// Send a signed transaction to the Solana blockchain
    /// - Parameter signedTransactionBase58: Base58-encoded signed transaction
    /// - Returns: Transaction signature
    func sendTransaction(signedTransactionBase58: String) async throws -> String
    
    /// Get signature statuses for transactions
    /// - Parameter signatures: Array of transaction signatures to check
    /// - Returns: Array of signature statuses
    func getSignatureStatuses(signatures: [String]) async throws -> [HeliusSignatureStatus?]
    
    // MARK: - Staking
    
    /// Get stake activation info for a stake account
    /// - Parameter stakeAccountAddress: The stake account public key
    /// - Returns: Stake activation details
    func getStakeActivation(stakeAccountAddress: String) async throws -> HeliusStakeActivationResult
    
    /// Get all program accounts owned by a specific program (using V2 API)
    /// - Parameters:
    ///   - programId: Program ID to filter by
    ///   - filters: Optional filters for the accounts
    ///   - limit: Maximum number of accounts to return
    /// - Returns: Program accounts response with pagination
    func getProgramAccountsV2(
        programId: String, 
        filters: [[String: Any]]?,
        limit: Int
    ) async throws -> HeliusProgramAccountsV2Response
    
    /// Get inflation reward for stake accounts
    /// - Parameters:
    ///   - addresses: Array of stake account addresses
    ///   - epoch: Optional epoch number (defaults to current epoch)
    /// - Returns: Array of inflation rewards
    func getInflationReward(addresses: [String], epoch: Int?) async throws -> [HeliusInflationReward?]
    
    /// Get current epoch information
    /// - Returns: Current epoch info
    func getEpochInfo() async throws -> HeliusEpochInfo
}

// MARK: - Live Implementation

actor LiveHeliusService: HeliusService {
    
    // MARK: - Properties
    
    private let apiKey = "f5a8f387-e31b-4283-905c-0ef8bd4eb576"
    private let rpcBaseURL = "https://mainnet.helius-rpc.com"
    private let restBaseURL = "https://api-mainnet.helius-rpc.com"
    
    private var rpcEndpoint: URL {
        URL(string: "\(rpcBaseURL)/?api-key=\(apiKey)")!
    }
    
    // MARK: - State
    
    private var cachedMetadata: [String: HeliusTokenMetadata] = [:]
    
    // MARK: - Setup
    
    func setup() async throws {
        print("🔮 HeliusService: Setup complete")
        print("   API Key: \(apiKey.prefix(8))...")
        print("   RPC: \(rpcBaseURL)")
        print("   REST: \(restBaseURL)")
    }
    
    // MARK: - Enhanced Balances
    
    func searchAssets(
        walletAddress: String,
        tokenType: String = "fungible",
        showZeroBalance: Bool = false
    ) async throws -> HeliusSearchAssetsResponse {
        let request = HeliusRequest(
            method: "searchAssets",
            params: [
                "ownerAddress": walletAddress,
                "tokenType": tokenType,
                "page": 1,
                "limit": 1000,
                "options": [
                    "showNativeBalance": true,
                    "showZeroBalance": showZeroBalance
                ]
            ]
        )
        
        let response: HeliusSearchAssetsResponse = try await makeRequest(request)
        
        print("🔮 HeliusService: Found \(response.result.total) assets (\(response.result.items.count) returned)")
        print("   Native SOL: \(response.result.nativeBalance?.total_price ?? 0) USD")
        return response
    }
    
    func getEnrichedBalances(walletAddress: String) async throws -> [HeliusTokenBalance] {
        let response = try await searchAssets(walletAddress: walletAddress, tokenType: "fungible")
        let assets = response.result.items
        
        // Convert to enriched balances
        let balances = assets.compactMap { asset -> HeliusTokenBalance? in
            guard let tokenInfo = asset.token_info else { return nil }
            
            return HeliusTokenBalance(
                mint: asset.id,
                symbol: tokenInfo.symbol ?? "UNKNOWN",
                name: tokenInfo.name ?? "Unknown Token",
                balance: tokenInfo.balance ?? 0,
                decimals: tokenInfo.decimals ?? 9,
                logoURI: asset.content?.links?.image,
                priceUSD: tokenInfo.price_info?.price_per_token,
                valueUSD: (tokenInfo.balance ?? 0) * (tokenInfo.price_info?.price_per_token ?? 0)
            )
        }
        
        print("🔮 HeliusService: Converted to \(balances.count) token balances")
        return balances
    }
    
    // MARK: - Token Metadata
    
    func getTokenMetadata(mint: String) async throws -> HeliusTokenMetadata {
        // Check cache
        if let cached = cachedMetadata[mint] {
            return cached
        }
        
        let request = HeliusRequest(
            method: "getAsset",
            params: ["id": mint]
        )
        
        let asset: HeliusAsset = try await makeRequest(request)
        
        let metadata = HeliusTokenMetadata(
            mint: asset.id,
            symbol: asset.content?.metadata?.symbol ?? "UNKNOWN",
            name: asset.content?.metadata?.name ?? "Unknown Token",
            decimals: asset.token_info?.decimals ?? 9,
            logoURI: asset.content?.links?.image,
            description: nil,
            coingeckoId: nil
        )
        
        cachedMetadata[mint] = metadata
        return metadata
    }
    
    // MARK: - Enhanced Transactions
    
    func getEnhancedTransactions(
        address: String,
        before: String? = nil,
        limit: Int = 50,
        type: String? = nil,
        source: String? = nil
    ) async throws -> [HeliusEnhancedTransaction] {
        // Build query parameters
        var queryItems: [URLQueryItem] = [
            URLQueryItem(name: "api-key", value: apiKey)
        ]
        
        if let before = before {
            queryItems.append(URLQueryItem(name: "before", value: before))
        }
        
        if limit > 0 && limit <= 100 {
            queryItems.append(URLQueryItem(name: "limit", value: String(limit)))
        }
        
        if let type = type {
            queryItems.append(URLQueryItem(name: "type", value: type))
        }
        
        if let source = source {
            queryItems.append(URLQueryItem(name: "source", value: source))
        }
        
        // Build URL
        var components = URLComponents(string: "\(restBaseURL)/v0/addresses/\(address)/transactions")!
        components.queryItems = queryItems
        
        guard let url = components.url else {
            throw HeliusServiceError.invalidResponse
        }
        
        // Make request
        let (data, response) = try await URLSession.shared.data(from: url)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw HeliusServiceError.invalidResponse
        }
        
        guard httpResponse.statusCode == 200 else {
            throw HeliusServiceError.httpError(httpResponse.statusCode)
        }
        
        let transactions = try JSONDecoder().decode([HeliusEnhancedTransaction].self, from: data)
        
        print("🔮 HeliusService: Fetched \(transactions.count) enhanced transactions")
        return transactions
    }
    
    // MARK: - Priority Fees
    
    func getPriorityFeeEstimate(
        transaction: String? = nil,
        accountKeys: [String]? = nil,
        includeAllLevels: Bool = false
    ) async throws -> HeliusPriorityFeeResponse {
        // Build params
        var params: [String: Any] = [:]
        
        if let transaction = transaction {
            params["transaction"] = transaction
        } else if let accountKeys = accountKeys {
            params["accountKeys"] = accountKeys
        } else {
            throw HeliusServiceError.invalidResponse
        }
        
        // Add options
        var options: [String: Any] = [:]
        if includeAllLevels {
            options["includeAllPriorityFeeLevels"] = true
        }
        
        if !options.isEmpty {
            params["options"] = options
        }
        
        // Note: This RPC method expects params as array with a single object
        var urlRequest = URLRequest(url: rpcEndpoint)
        urlRequest.httpMethod = "POST"
        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let requestBody: [String: Any] = [
            "jsonrpc": "2.0",
            "id": UUID().uuidString,
            "method": "getPriorityFeeEstimate",
            "params": [params]
        ]
        
        urlRequest.httpBody = try JSONSerialization.data(withJSONObject: requestBody)
        
        let (data, response) = try await URLSession.shared.data(for: urlRequest)
        
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            throw HeliusServiceError.invalidResponse
        }
        
        // Decode the RPC response
        let rpcResponse = try JSONDecoder().decode(HeliusRPCResponse<HeliusPriorityFeeResponse>.self, from: data)
        
        guard let result = rpcResponse.result else {
            if let error = rpcResponse.error {
                throw HeliusServiceError.apiError(error.message)
            }
            throw HeliusServiceError.invalidResponse
        }
        
        if let estimate = result.priorityFeeEstimate {
            print("🔮 HeliusService: Priority fee estimate: \(estimate) microlamports")
        } else if let levels = result.priorityFeeLevels {
            print("🔮 HeliusService: Priority fee levels:")
            print("   Medium: \(levels.medium) microlamports")
            print("   High: \(levels.high) microlamports")
        }
        
        return result
    }
    
    // MARK: - Webhooks
    
    func createBalanceWebhook(walletAddress: String, webhookURL: String) async throws -> String {
        // Helius Webhooks API
        let url = URL(string: "\(restBaseURL)/v0/webhooks?api-key=\(apiKey)")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let body: [String: Any] = [
            "webhookURL": webhookURL,
            "transactionTypes": ["ANY"],
            "accountAddresses": [walletAddress],
            "webhookType": "enhanced"
        ]
        
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        
        let (data, _) = try await URLSession.shared.data(for: request)
        let response = try JSONDecoder().decode([String: String].self, from: data)
        
        guard let webhookID = response["webhookID"] else {
            throw HeliusServiceError.invalidResponse
        }
        
        print("🔮 HeliusService: Created webhook \(webhookID)")
        return webhookID
    }
    
    // MARK: - Transaction History
    
    func getTransactionsForAddress(
        address: String,
        limit: Int = 100,
        sortOrder: String = "desc",
        transactionDetails: String = "signatures"
    ) async throws -> HeliusTransactionsForAddressResponse {
        let requestBody: [String: Any] = [
            "jsonrpc": "2.0",
            "id": UUID().uuidString,
            "method": "getTransactionsForAddress",
            "params": [
                address,
                [
                    "transactionDetails": transactionDetails,
                    "sortOrder": sortOrder,
                    "limit": limit
                ] as [String : Any]
            ] as [Any]
        ]
        
        let jsonData = try JSONSerialization.data(withJSONObject: requestBody)
        
        var urlRequest = URLRequest(url: rpcEndpoint)
        urlRequest.httpMethod = "POST"
        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        urlRequest.httpBody = jsonData
        
        let (data, _) = try await URLSession.shared.data(for: urlRequest)
        let rpcResponse = try JSONDecoder().decode(HeliusTransactionsForAddressRPCResponse.self, from: data)
        
        if let error = rpcResponse.error {
            throw HeliusServiceError.apiError(error.message)
        }
        
        guard let result = rpcResponse.result else {
            throw HeliusServiceError.invalidResponse
        }
        
        return result
    }
    
    func getFirstTransaction(address: String) async throws -> HeliusTransactionSignature? {
        // Fetch with ascending order (oldest first) and limit 1
        let response = try await getTransactionsForAddress(
            address: address,
            limit: 1,
            sortOrder: "asc", // Oldest first
            transactionDetails: "signatures"
        )
        
        return response.data.first
    }
    
    // MARK: - Private Helpers
    
    private func makeRequest<T: Decodable>(_ request: HeliusRequest) async throws -> T {
        var urlRequest = URLRequest(url: rpcEndpoint)
        urlRequest.httpMethod = "POST"
        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let body: [String: Any] = [
            "jsonrpc": "2.0",
            "id": UUID().uuidString,
            "method": request.method,
            "params": request.params
        ]
        
        urlRequest.httpBody = try JSONSerialization.data(withJSONObject: body)
        
        let (data, response) = try await URLSession.shared.data(for: urlRequest)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw HeliusServiceError.invalidResponse
        }
        
        guard httpResponse.statusCode == 200 else {
            throw HeliusServiceError.httpError(httpResponse.statusCode)
        }
        
        // Try to decode as RPC response
        if let rpcResponse = try? JSONDecoder().decode(HeliusRPCResponse<T>.self, from: data) {
            if let error = rpcResponse.error {
                throw HeliusServiceError.apiError(error.message)
            }
            guard let result = rpcResponse.result else {
                throw HeliusServiceError.invalidResponse
            }
            return result
        }
        
        // Try direct decode
        return try JSONDecoder().decode(T.self, from: data)
    }
    
    // MARK: - Transaction Submission
    
    func sendTransaction(signedTransactionBase58: String) async throws -> String {
        print("📤 HeliusService: Sending transaction...")
        
        let rpcRequest: [String: Any] = [
            "jsonrpc": "2.0",
            "id": "1",
            "method": "sendTransaction",
            "params": [signedTransactionBase58]
        ]
        
        let requestData = try JSONSerialization.data(withJSONObject: rpcRequest)
        
        var request = URLRequest(url: rpcEndpoint)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = requestData
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw HeliusServiceError.invalidResponse
        }
        
        guard httpResponse.statusCode == 200 else {
            let errorText = String(data: data, encoding: .utf8) ?? "Unknown error"
            throw HeliusServiceError.httpError(httpResponse.statusCode)
        }
        
        // Parse response
        struct SendTransactionResponse: Codable {
            let jsonrpc: String
            let id: String
            let result: String?
            let error: RPCError?
            
            struct RPCError: Codable {
                let code: Int
                let message: String
            }
        }
        
        let rpcResponse = try JSONDecoder().decode(SendTransactionResponse.self, from: data)
        
        if let error = rpcResponse.error {
            throw HeliusServiceError.apiError(error.message)
        }
        
        guard let signature = rpcResponse.result else {
            throw HeliusServiceError.apiError("No signature returned from RPC")
        }
        
        print("✅ HeliusService: Transaction sent!")
        print("   Signature: \(signature)")
        
        return signature
    }
    
    func getSignatureStatuses(signatures: [String]) async throws -> [HeliusSignatureStatus?] {
        print("🔍 HeliusService: Checking signature statuses...")
        
        let rpcRequest: [String: Any] = [
            "jsonrpc": "2.0",
            "id": "1",
            "method": "getSignatureStatuses",
            "params": [signatures]
        ]
        
        let requestData = try JSONSerialization.data(withJSONObject: rpcRequest)
        
        var request = URLRequest(url: rpcEndpoint)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = requestData
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw HeliusServiceError.invalidResponse
        }
        
        guard httpResponse.statusCode == 200 else {
            throw HeliusServiceError.httpError(httpResponse.statusCode)
        }
        
        let rpcResponse = try JSONDecoder().decode(HeliusSignatureStatusResponse.self, from: data)
        
        return rpcResponse.result.value
    }
    
    // MARK: - Staking
    
    func getStakeActivation(stakeAccountAddress: String) async throws -> HeliusStakeActivationResult {
        print("🔍 HeliusService: Getting stake activation for \(stakeAccountAddress)")
        
        let rpcRequest: [String: Any] = [
            "jsonrpc": "2.0",
            "id": "1",
            "method": "getStakeActivation",
            "params": [stakeAccountAddress]
        ]
        
        let requestData = try JSONSerialization.data(withJSONObject: rpcRequest)
        
        var request = URLRequest(url: rpcEndpoint)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = requestData
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw HeliusServiceError.invalidResponse
        }
        
        guard httpResponse.statusCode == 200 else {
            throw HeliusServiceError.httpError(httpResponse.statusCode)
        }
        
        let rpcResponse = try JSONDecoder().decode(HeliusStakeActivationResponse.self, from: data)
        
        print("🔍 HeliusService: Stake activation - State: \(rpcResponse.result.state)")
        return rpcResponse.result
    }
    
    func getProgramAccountsV2(
        programId: String,
        filters: [[String: Any]]? = nil,
        limit: Int = 1000
    ) async throws -> HeliusProgramAccountsV2Response {
        print("🔍 HeliusService: Getting program accounts V2 for \(programId)")
        
        var config: [String: Any] = [
            "encoding": "jsonParsed",
            "limit": limit
        ]
        
        if let filters = filters {
            config["filters"] = filters
        }
        
        let params: [Any] = [programId, config]
        
        let rpcRequest: [String: Any] = [
            "jsonrpc": "2.0",
            "id": "1",
            "method": "getProgramAccountsV2",
            "params": params
        ]
        
        let requestData = try JSONSerialization.data(withJSONObject: rpcRequest)
        
        // Debug print the request
        if let jsonString = String(data: requestData, encoding: .utf8) {
            print("🔍 HeliusService: Request: \(jsonString)")
        }
        
        var request = URLRequest(url: rpcEndpoint)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = requestData
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw HeliusServiceError.invalidResponse
        }
        
        // Debug print response
        if let responseString = String(data: data, encoding: .utf8) {
            print("🔍 HeliusService: Response (\(httpResponse.statusCode)): \(responseString.prefix(500))")
        }
        
        guard httpResponse.statusCode == 200 else {
            throw HeliusServiceError.httpError(httpResponse.statusCode)
        }
        
        struct ProgramAccountsV2RPCResponse: Codable {
            let jsonrpc: String
            let result: HeliusProgramAccountsV2Response
            let id: String
        }
        
        let rpcResponse = try JSONDecoder().decode(ProgramAccountsV2RPCResponse.self, from: data)
        
        print("🔍 HeliusService: Found \(rpcResponse.result.accounts.count) program accounts")
        if let totalResults = rpcResponse.result.totalResults {
            print("   Total results: \(totalResults)")
        }
        
        return rpcResponse.result
    }
    
    func getInflationReward(addresses: [String], epoch: Int? = nil) async throws -> [HeliusInflationReward?] {
        print("🔍 HeliusService: Getting inflation rewards for \(addresses.count) addresses")
        
        var params: [Any] = [addresses]
        
        if let epoch = epoch {
            params.append(["epoch": epoch])
        }
        
        let rpcRequest: [String: Any] = [
            "jsonrpc": "2.0",
            "id": "1",
            "method": "getInflationReward",
            "params": params
        ]
        
        let requestData = try JSONSerialization.data(withJSONObject: rpcRequest)
        
        var request = URLRequest(url: rpcEndpoint)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = requestData
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw HeliusServiceError.invalidResponse
        }
        
        guard httpResponse.statusCode == 200 else {
            throw HeliusServiceError.httpError(httpResponse.statusCode)
        }
        
        struct InflationRewardResponse: Codable {
            let jsonrpc: String
            let result: [HeliusInflationReward?]
            let id: String
        }
        
        let rpcResponse = try JSONDecoder().decode(InflationRewardResponse.self, from: data)
        
        print("🔍 HeliusService: Got inflation rewards")
        return rpcResponse.result
    }
    
    func getEpochInfo() async throws -> HeliusEpochInfo {
        print("🔍 HeliusService: Getting epoch info")
        
        let rpcRequest: [String: Any] = [
            "jsonrpc": "2.0",
            "id": "1",
            "method": "getEpochInfo",
            "params": []
        ]
        
        let requestData = try JSONSerialization.data(withJSONObject: rpcRequest)
        
        var request = URLRequest(url: rpcEndpoint)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = requestData
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw HeliusServiceError.invalidResponse
        }
        
        guard httpResponse.statusCode == 200 else {
            throw HeliusServiceError.httpError(httpResponse.statusCode)
        }
        
        struct EpochInfoResponse: Codable {
            let jsonrpc: String
            let result: HeliusEpochInfo
            let id: String
        }
        
        let rpcResponse = try JSONDecoder().decode(EpochInfoResponse.self, from: data)
        
        print("🔍 HeliusService: Epoch \(rpcResponse.result.epoch), slot \(rpcResponse.result.slotIndex)/\(rpcResponse.result.slotsInEpoch)")
        return rpcResponse.result
    }
}

// MARK: - Request/Response Models

struct HeliusRequest {
    let method: String
    let params: [String: Any]
}

struct HeliusRPCResponse<T: Decodable>: Decodable {
    let jsonrpc: String
    let id: String
    let result: T?
    let error: HeliusRPCError?
}

struct HeliusRPCError: Decodable {
    let code: Int
    let message: String
}

// MARK: - Errors

enum HeliusServiceError: Error, LocalizedError {
    case notInitialized
    case invalidResponse
    case httpError(Int)
    case apiError(String)
    
    var errorDescription: String? {
        switch self {
        case .notInitialized:
            return "Helius service not initialized. Call setup() first."
        case .invalidResponse:
            return "Invalid response from Helius API"
        case .httpError(let code):
            return "HTTP error: \(code)"
        case .apiError(let message):
            return "Helius API error: \(message)"
        }
    }
}

// MARK: - Dependency

extension DependencyValues {
    var heliusService: HeliusService {
        get { self[HeliusServiceKey.self] }
        set { self[HeliusServiceKey.self] = newValue }
    }
}

private enum HeliusServiceKey: DependencyKey {
    static let liveValue: HeliusService = LiveHeliusService()
    static let testValue: HeliusService = { fatalError("HeliusService not mocked for tests") }()
}
