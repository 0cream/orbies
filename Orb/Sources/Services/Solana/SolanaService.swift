import Dependencies
import Foundation

// TODO: Add Sendable conformance to SolanaSwift types or update to concurrency-aware version
@preconcurrency import SolanaSwift

// MARK: - Protocol

protocol SolanaService: Actor {
    
    // MARK: - Setup
    
    func setup() async throws
    
    // MARK: - Balances
    
    /// Get SOL balance for a wallet
    func getSolBalance(walletAddress: String) async throws -> Double
    
    /// Get specific SPL token balance
    func getTokenBalance(walletAddress: String, mint: String) async throws -> Double
    
    /// Get all token accounts for a wallet
    func getTokenAccounts(walletAddress: String) async throws -> [TokenAccountInfo]
    
    // MARK: - Transactions
    
    /// Send SOL to another address
    func sendSOL(from: String, to: String, amount: Double) async throws -> String
    
    /// Send SPL token to another address
    func sendToken(from: String, to: String, mint: String, amount: Double) async throws -> String
    
    /// Get transaction signatures for an address
    func getSignaturesForAddress(address: String, limit: Int) async throws -> [String]
    
    /// Get transaction details
    func getTransaction(signature: String) async throws -> SolanaTransactionInfo
    
    // MARK: - Account Info
    
    /// Get account info for any address
    func getAccountInfo(address: String) async throws -> AccountInfoData?
    
    /// Check if an account exists
    func accountExists(address: String) async throws -> Bool
}

// MARK: - Live Implementation

actor LiveSolanaService: SolanaService {
    
    // MARK: - Properties
    
    private var apiClient: SolanaAPIClient?
    private var blockchainClient: BlockchainClient?
    
    private let endpoint = APIEndPoint(
        address: "https://mainnet.helius-rpc.com/?api-key=f5a8f387-e31b-4283-905c-0ef8bd4eb576",
        network: .mainnetBeta
    )
    
    // MARK: - Setup
    
    func setup() async throws {
        self.apiClient = JSONRPCAPIClient(endpoint: endpoint)
        self.blockchainClient = BlockchainClient(apiClient: apiClient!)
        
        print("⚡️ SolanaService: Setup complete")
        print("   Network: Mainnet Beta")
        print("   RPC: Helius")
    }
    
    // MARK: - Balances
    
    func getSolBalance(walletAddress: String) async throws -> Double {
        guard let apiClient = apiClient else {
            throw SolanaServiceError.notInitialized
        }
        
        // Get balance in lamports
        let lamports = try await apiClient.getBalance(
            account: walletAddress,
            commitment: "confirmed"
        )
        
        // Convert lamports to SOL (1 SOL = 1,000,000,000 lamports)
        let sol = Double(lamports) / 1_000_000_000
        
        print("⚡️ SolanaService: SOL balance for \(walletAddress): \(sol)")
        return sol
    }
    
    func getTokenBalance(walletAddress: String, mint: String) async throws -> Double {
        guard let apiClient = apiClient else {
            throw SolanaServiceError.notInitialized
        }
        
        // Get token accounts for this mint
        let accounts = try await apiClient.getTokenAccountsByOwner(
            pubkey: walletAddress,
            params: .init(mint: mint, programId: nil),
            configs: nil,
            decodingTo: TokenAccountState.self
        )
        
        // Sum all balances (lamports is in smallest unit, need decimals to convert)
        // For now, return raw lamports sum
        let totalLamports = accounts
            .map { $0.account.data.lamports }
            .reduce(0, +)
        
        // TODO: Get token decimals and convert properly
        // For now, assume 9 decimals (SOL standard)
        let totalBalance = Double(totalLamports) / 1_000_000_000
        
        print("⚡️ SolanaService: Token balance for \(mint): \(totalBalance)")
        return totalBalance
    }
    
    func getTokenAccounts(walletAddress: String) async throws -> [TokenAccountInfo] {
        guard let apiClient = apiClient else {
            throw SolanaServiceError.notInitialized
        }
        
        // Get all token accounts (without filtering by mint)
        let accounts = try await apiClient.getTokenAccountsByOwner(
            pubkey: walletAddress,
            params: .init(mint: nil, programId: TokenProgram.id.base58EncodedString),
            configs: nil,
            decodingTo: TokenAccountState.self
        )
        
        let tokenAccounts = accounts.map { account -> TokenAccountInfo in
            let data = account.account.data
            
            // TODO: Get token decimals from mint to properly convert balance
            // For now, assume 9 decimals
            let balance = Double(data.lamports) / 1_000_000_000
            
            return TokenAccountInfo(
                address: account.pubkey,
                mint: data.mint.base58EncodedString,
                balance: balance,
                decimals: 9 // Default, should fetch from mint account
            )
        }
        
        print("⚡️ SolanaService: Found \(tokenAccounts.count) token accounts")
        return tokenAccounts
    }
    
    // MARK: - Transactions
    
    func sendSOL(from: String, to: String, amount: Double) async throws -> String {
        guard let blockchainClient = blockchainClient else {
            throw SolanaServiceError.notInitialized
        }
        
        // This would require wallet signing - not implemented yet
        throw SolanaServiceError.notImplemented
    }
    
    func sendToken(from: String, to: String, mint: String, amount: Double) async throws -> String {
        guard let blockchainClient = blockchainClient else {
            throw SolanaServiceError.notInitialized
        }
        
        // This would require wallet signing - not implemented yet
        throw SolanaServiceError.notImplemented
    }
    
    func getSignaturesForAddress(address: String, limit: Int = 50) async throws -> [String] {
        guard let apiClient = apiClient else {
            throw SolanaServiceError.notInitialized
        }
        
        let signatures = try await apiClient.getSignaturesForAddress(
            address: address,
            configs: RequestConfiguration(limit: limit)
        )
        
        return signatures.map { $0.signature }
    }
    
    func getTransaction(signature: String) async throws -> SolanaTransactionInfo {
        guard let apiClient = apiClient else {
            throw SolanaServiceError.notInitialized
        }
        
        // Get transaction with full details
        let transaction = try await apiClient.getTransaction(
            signature: signature,
            commitment: "confirmed"
        )
        
        // Parse transaction info
        return SolanaTransactionInfo(
            signature: signature,
            slot: transaction?.slot ?? 0,
            blockTime: transaction?.blockTime != nil ? Date(timeIntervalSince1970: TimeInterval(transaction!.blockTime!)) : nil,
            fee: Double(transaction?.meta?.fee ?? 0) / 1_000_000_000
        )
    }
    
    // MARK: - Account Info
    
    func getAccountInfo(address: String) async throws -> AccountInfoData? {
        guard let apiClient = apiClient else {
            throw SolanaServiceError.notInitialized
        }
        
        let accountInfo: BufferInfo<EmptyInfo>? = try await apiClient.getAccountInfo(account: address)
        
        guard let info = accountInfo else {
            return nil
        }
        
        return AccountInfoData(
            lamports: info.lamports,
            owner: info.owner,
            executable: info.executable,
            rentEpoch: info.rentEpoch
        )
    }
    
    func accountExists(address: String) async throws -> Bool {
        let info = try await getAccountInfo(address: address)
        return info != nil
    }
}

// MARK: - Models

struct TokenAccountInfo: Codable, Equatable {
    let address: String
    let mint: String
    let balance: Double
    let decimals: Int
}

struct SolanaTransactionInfo: Codable, Equatable {
    let signature: String
    let slot: UInt64
    let blockTime: Date?
    let fee: Double
}

struct AccountInfoData: Codable, Equatable {
    let lamports: UInt64
    let owner: String
    let executable: Bool
    let rentEpoch: UInt64
}

// MARK: - Errors

enum SolanaServiceError: Error, LocalizedError {
    case notInitialized
    case notImplemented
    case invalidAddress
    case transactionFailed(String)
    
    var errorDescription: String? {
        switch self {
        case .notInitialized:
            return "Solana service not initialized. Call setup() first."
        case .notImplemented:
            return "Feature not yet implemented"
        case .invalidAddress:
            return "Invalid Solana address"
        case .transactionFailed(let reason):
            return "Transaction failed: \(reason)"
        }
    }
}

// MARK: - Dependency

extension DependencyValues {
    var solanaService: SolanaService {
        get { self[SolanaServiceKey.self] }
        set { self[SolanaServiceKey.self] = newValue }
    }
}

private enum SolanaServiceKey: DependencyKey {
    static let liveValue: SolanaService = LiveSolanaService()
    static let testValue: SolanaService = { fatalError("SolanaService not mocked for tests") }()
}

