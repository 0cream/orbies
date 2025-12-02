import Foundation

// MARK: - Enhanced Token Balance

struct HeliusTokenBalance: Codable, Equatable, Identifiable {
    let mint: String
    let symbol: String
    let name: String
    let balance: Double
    let decimals: Int
    let logoURI: String?
    let priceUSD: Double?
    let valueUSD: Double
    
    var id: String { mint }
    
    var displayBalance: String {
        String(format: "%.2f", balance)
    }
    
    var displayValue: String? {
        guard valueUSD > 0 else { return nil }
        return String(format: "$%.2f", valueUSD)
    }
    
    var isStablecoin: Bool {
        return symbol.uppercased() == "USDC" || symbol.uppercased() == "USDT"
    }
}

// MARK: - Token Metadata

struct HeliusTokenMetadata: Codable, Equatable, Identifiable {
    let mint: String
    let symbol: String
    let name: String
    let decimals: Int
    let logoURI: String?
    let description: String?
    let coingeckoId: String?
    
    var id: String { mint }
}

// MARK: - Search Assets Response

struct HeliusSearchAssetsResponse: Codable {
    let jsonrpc: String
    let result: HeliusSearchAssetsResult
    let id: String
}

struct HeliusSearchAssetsResult: Codable {
    let last_indexed_slot: Int?
    let total: Int
    let limit: Int
    let page: Int
    let items: [HeliusAsset]
    let nativeBalance: HeliusNativeBalance?
    let cursor: String?
}

struct HeliusNativeBalance: Codable {
    let lamports: Int
    let price_per_sol: Double
    let total_price: Double
    
    var sol: Double {
        Double(lamports) / 1_000_000_000
    }
}

struct HeliusAsset: Codable {
    let id: String // mint address
    let content: HeliusAssetContent?
    let token_info: HeliusTokenInfo?
}

struct HeliusAssetContent: Codable {
    let metadata: HeliusMetadata?
    let links: HeliusLinks?
}

struct HeliusMetadata: Codable {
    let name: String?
    let symbol: String?
}

struct HeliusLinks: Codable {
    let image: String?
}

struct HeliusTokenInfo: Codable {
    let symbol: String?
    let name: String?
    let balance: Double?
    let decimals: Int?
    let price_info: HeliusPriceInfo?
}

struct HeliusPriceInfo: Codable {
    let price_per_token: Double?
    let currency: String?
}

// MARK: - Enhanced Transaction Models

struct HeliusEnhancedTransaction: Codable, Identifiable, Sendable {
    let signature: String
    let description: String?
    let type: String
    let source: String
    let fee: Int
    let feePayer: String
    let slot: Int
    let timestamp: Int
    let nativeTransfers: [HeliusNativeTransfer]?
    let tokenTransfers: [HeliusTokenTransfer]?
    let accountData: [HeliusAccountData]?
    let transactionError: HeliusTransactionError?
    let instructions: [HeliusInstruction]?
    let events: HeliusTransactionEvents?
    
    var id: String { signature }
    
    var date: Date {
        Date(timeIntervalSince1970: TimeInterval(timestamp))
    }
    
    var feeInSOL: Double {
        Double(fee) / 1_000_000_000
    }
}

struct HeliusNativeTransfer: Codable, Equatable {
    let fromUserAccount: String
    let toUserAccount: String
    let amount: Int
    
    var amountInSOL: Double {
        Double(amount) / 1_000_000_000
    }
}

struct HeliusTokenTransfer: Codable, Equatable {
    let fromUserAccount: String
    let toUserAccount: String
    let fromTokenAccount: String
    let toTokenAccount: String
    let tokenAmount: Double
    let mint: String
}

struct HeliusAccountData: Codable {
    let account: String
    let nativeBalanceChange: Double
    let tokenBalanceChanges: [HeliusTokenBalanceChange]?
}

struct HeliusTokenBalanceChange: Codable {
    let userAccount: String
    let tokenAccount: String
    let mint: String
    let rawTokenAmount: HeliusRawTokenAmount
}

struct HeliusRawTokenAmount: Codable {
    let tokenAmount: String
    let decimals: Int
}

struct HeliusTransactionError: Codable {
    let error: String
}

struct HeliusInstruction: Codable {
    let accounts: [String]
    let data: String
    let programId: String
    let innerInstructions: [HeliusInnerInstruction]?
}

struct HeliusInnerInstruction: Codable {
    let accounts: [String]
    let data: String
    let programId: String
}

struct HeliusTransactionEvents: Codable {
    let nft: HeliusNFTEvent?
    let swap: HeliusSwapEvent?
    let compressed: [HeliusCompressedNFTEvent]?
}

struct HeliusNFTEvent: Codable {
    let description: String?
    let type: String
    let source: String
    let amount: Int
    let buyer: String?
    let seller: String?
    let nfts: [HeliusNFTToken]?
}

struct HeliusNFTToken: Codable {
    let mint: String
    let tokenStandard: String
}

struct HeliusSwapEvent: Codable {
    let nativeInput: HeliusNativeBalanceChange?
    let nativeOutput: HeliusNativeBalanceChange?
    let tokenInputs: [HeliusTokenBalanceChange]?
    let tokenOutputs: [HeliusTokenBalanceChange]?
    let innerSwaps: [HeliusInnerSwap]?
}

struct HeliusNativeBalanceChange: Codable {
    let account: String
    let amount: String
    
    var amountDouble: Double {
        Double(amount) ?? 0
    }
}

struct HeliusInnerSwap: Codable {
    let tokenInputs: [HeliusTokenTransfer]?
    let tokenOutputs: [HeliusTokenTransfer]?
    let programInfo: HeliusProgramInfo?
}

struct HeliusProgramInfo: Codable {
    let source: String
    let account: String
    let programName: String
    let instructionName: String
}

struct HeliusCompressedNFTEvent: Codable {
    let type: String
    let treeId: String?
    let assetId: String?
    let leafIndex: Int?
}

// MARK: - Priority Fee Models

struct HeliusPriorityFeeResponse: Codable {
    let priorityFeeEstimate: Double?
    let priorityFeeLevels: HeliusPriorityFeeLevels?
    
    /// Convert microlamports to lamports
    func estimateInLamports() -> Int? {
        guard let estimate = priorityFeeEstimate else { return nil }
        return Int(estimate)
    }
    
    /// Convert microlamports to SOL
    func estimateInSOL() -> Double? {
        guard let estimate = priorityFeeEstimate else { return nil }
        return estimate / 1_000_000_000
    }
}

struct HeliusPriorityFeeLevels: Codable {
    let min: Double
    let low: Double
    let medium: Double
    let high: Double
    let veryHigh: Double
    let unsafeMax: Double
    
    /// Get recommended fee (medium is usually good balance)
    var recommended: Double {
        medium
    }
    
    /// Convert level to lamports
    func toLamports(_ level: PriorityLevel) -> Int {
        let microlamports: Double
        switch level {
        case .min: microlamports = min
        case .low: microlamports = low
        case .medium: microlamports = medium
        case .high: microlamports = high
        case .veryHigh: microlamports = veryHigh
        case .unsafeMax: microlamports = unsafeMax
        }
        return Int(microlamports)
    }
}

enum PriorityLevel: String, Codable {
    case min = "Min"
    case low = "Low"
    case medium = "Medium"
    case high = "High"
    case veryHigh = "VeryHigh"
    case unsafeMax = "UnsafeMax"
}

// MARK: - Known Token Mints

extension HeliusTokenBalance {
    /// Well-known Solana token mint addresses
    static let knownMints = KnownMints()
    
    struct KnownMints {
        /// USDC (USD Coin)
        let usdc = "EPjFWdd5AufqSSqeM2qN1xzybapC8G4wEGGkZwyTDt1v"
        
        /// SOL (Native Solana - wrapped)
        let sol = "So11111111111111111111111111111111111111112"
        
        /// USDT (Tether)
        let usdt = "Es9vMFrzaCERmJfrF4H2FYD4KCoNkY11McCe8BenwNYB"
        
        /// RAY (Raydium)
        let ray = "4k3Dyjzvzp8eMZWUXbBCjEvwSkkk59S5iCNLY3QrkX6R"
        
        /// BONK
        let bonk = "DezXAZ8z7PnrnRJjz3wXBoRgixCa6xjnB7YaB1pPB263"
        
        /// JUP (Jupiter)
        let jup = "JUPyiwrYJFskUPiHa7hkeR8VUtAeFoSYbKedZNsDvCN"
        
        /// WIF (dogwifhat)
        let wif = "EKpQGSJtjMFqKZ9KQanSqYXRcF8fBopzLHYxdM65zcjm"
    }
}

// MARK: - Transactions For Address

struct HeliusTransactionsForAddressRPCResponse: Codable {
    let jsonrpc: String
    let id: String
    let result: HeliusTransactionsForAddressResponse?
    let error: HeliusRPCErrorDetail?
}

struct HeliusRPCErrorDetail: Codable {
    let code: Int
    let message: String
}

struct HeliusTransactionsForAddressResponse: Codable, Sendable {
    let data: [HeliusTransactionSignature]
    let paginationToken: String?
}

struct HeliusTransactionSignature: Codable, Sendable {
    let signature: String
    let slot: Int
    let err: AnyCodable?
    let memo: String?
    let blockTime: Int?
    let confirmationStatus: String?
}

// Helper to decode any type
struct AnyCodable: Codable, @unchecked Sendable {
    let value: Any
    
    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        
        if container.decodeNil() {
            value = NSNull()
        } else if let bool = try? container.decode(Bool.self) {
            value = bool
        } else if let int = try? container.decode(Int.self) {
            value = int
        } else if let double = try? container.decode(Double.self) {
            value = double
        } else if let string = try? container.decode(String.self) {
            value = string
        } else if let array = try? container.decode([AnyCodable].self) {
            value = array.map { $0.value }
        } else if let dict = try? container.decode([String: AnyCodable].self) {
            value = dict.mapValues { $0.value }
        } else {
            value = NSNull()
        }
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        
        switch value {
        case is NSNull:
            try container.encodeNil()
        case let bool as Bool:
            try container.encode(bool)
        case let int as Int:
            try container.encode(int)
        case let double as Double:
            try container.encode(double)
        case let string as String:
            try container.encode(string)
        default:
            try container.encodeNil()
        }
    }
}

// MARK: - Signature Status

struct HeliusSignatureStatusResponse: Codable {
    let jsonrpc: String
    let result: HeliusSignatureStatusResult
    let id: String
}

struct HeliusSignatureStatusResult: Codable {
    let context: HeliusContext
    let value: [HeliusSignatureStatus?]
}

struct HeliusContext: Codable {
    let slot: Int
}

struct HeliusSignatureStatus: Codable {
    let slot: Int
    let confirmations: Int?
    let err: HeliusTransactionError?
    let confirmationStatus: String?
    
    var isFinalized: Bool {
        confirmationStatus == "finalized"
    }
    
    var isConfirmed: Bool {
        confirmationStatus == "confirmed" || confirmationStatus == "finalized"
    }
}

// MARK: - Stake Account Models

struct HeliusStakeActivationResponse: Codable {
    let jsonrpc: String
    let result: HeliusStakeActivationResult
    let id: String
}

struct HeliusStakeActivationResult: Codable {
    let state: String // "active", "activating", "deactivating", "inactive"
    let active: UInt64 // lamports actively staked
    let inactive: UInt64 // lamports not active
}

struct HeliusProgramAccount: Codable {
    let pubkey: String
    let account: HeliusProgramAccountData
}

struct HeliusProgramAccountData: Codable {
    let lamports: UInt64
    let owner: String?
    let data: HeliusParsedAccountData
    let executable: Bool?
    let rentEpoch: UInt64?
}

struct HeliusParsedAccountData: Codable {
    let program: String
    let parsed: HeliusParsedStakeAccount
}

struct HeliusParsedStakeAccount: Codable {
    let info: HeliusParsedStakeInfo
    let type: String
}

struct HeliusParsedStakeInfo: Codable {
    let meta: HeliusStakeAccountMeta
    let stake: HeliusStakeAccountStake?
}

// Parsed stake account data
struct HeliusStakeAccountInfo: Codable {
    let type: String
    let info: HeliusStakeAccountDetails
}

struct HeliusStakeAccountDetails: Codable {
    let meta: HeliusStakeAccountMeta
    let stake: HeliusStakeAccountStake?
}

struct HeliusStakeAccountMeta: Codable {
    let rentExemptReserve: String
    let authorized: HeliusStakeAccountAuthorized
    let lockup: HeliusStakeAccountLockup
}

struct HeliusStakeAccountAuthorized: Codable {
    let staker: String
    let withdrawer: String
}

struct HeliusStakeAccountLockup: Codable {
    let unixTimestamp: Int
    let epoch: UInt64
    let custodian: String
}

struct HeliusStakeAccountStake: Codable {
    let delegation: HeliusStakeAccountDelegation
    let creditsObserved: UInt64
}

struct HeliusStakeAccountDelegation: Codable {
    let voter: String
    let stake: String
    let activationEpoch: String
    let deactivationEpoch: String
    let warmupCooldownRate: Double
}

// MARK: - Program Accounts V2 Response

struct HeliusProgramAccountsV2Response: Codable {
    let accounts: [HeliusProgramAccount]
    let paginationKey: String?
    let totalResults: Int?
}

// MARK: - Inflation Reward Models

struct HeliusInflationReward: Codable {
    let epoch: Int
    let effectiveSlot: Int
    let amount: Int // lamports
    let postBalance: Int // lamports
    let commission: Int? // Validator commission, null if not available
}

// MARK: - Epoch Info Models

struct HeliusEpochInfo: Codable {
    let absoluteSlot: Int
    let blockHeight: Int
    let epoch: Int
    let slotIndex: Int
    let slotsInEpoch: Int
    let transactionCount: Int?
}
