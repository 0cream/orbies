import Dependencies
import Foundation
import Security

// TODO: Add Sendable conformance to SolanaSwift types or update to concurrency-aware version
@preconcurrency import SolanaSwift

// MARK: - Wallet Service Protocol

/// Service for managing user's Solana wallet (keypair)
/// Provides secure storage and retrieval of private keys using iOS Keychain
protocol WalletService: Actor {
    
    // MARK: - Wallet Access
    
    /// Get the user's public key (wallet address)
    /// - Returns: Base58-encoded public key string
    func getPublicKey() async throws -> String
    
    /// Get the user's full keypair (includes private key)
    /// ⚠️ Handle with care - contains sensitive data
    /// - Returns: Solana keypair (public + private keys)
    func getKeypair() async throws -> SolanaSwift.KeyPair
    
    /// Check if a wallet exists in Keychain
    /// - Returns: true if wallet exists, false otherwise
    func hasWallet() async -> Bool
    
    /// Get wallet initialization timestamp (first transaction timestamp)
    /// - Returns: Unix timestamp of first transaction, or nil if not set
    func getInitializationTimestamp() async -> Int?
    
    /// Set wallet initialization timestamp
    /// - Parameter timestamp: Unix timestamp of first transaction
    func setInitializationTimestamp(_ timestamp: Int) async throws
    
    // MARK: - Wallet Management
    
    /// Create a new random wallet and store in Keychain
    /// - Returns: The newly created wallet address
    /// - Throws: WalletServiceError if wallet already exists or creation fails
    func createWallet() async throws -> String
    
    /// Import wallet from seed phrase and store in Keychain
    /// - Parameter seedPhrase: 12 or 24 word BIP39 mnemonic
    /// - Returns: The imported wallet address
    /// - Throws: WalletServiceError if seed phrase is invalid
    func importWallet(seedPhrase: [String]) async throws -> String
    
    /// Import wallet from private key and store in Keychain
    /// - Parameter privateKey: Base58-encoded private key
    /// - Returns: The imported wallet address
    /// - Throws: WalletServiceError if private key is invalid
    func importWallet(privateKey: String) async throws -> String
    
    /// Export wallet seed phrase (if available)
    /// ⚠️ Only available for wallets created or imported with seed phrase
    /// - Returns: 12 or 24 word mnemonic array
    /// - Throws: WalletServiceError if wallet doesn't have seed phrase
    func exportSeedPhrase() async throws -> [String]
    
    /// Export wallet private key
    /// ⚠️ Handle with extreme care - anyone with this can control the wallet
    /// - Returns: Base58-encoded private key
    func exportPrivateKey() async throws -> String
    
    /// Delete wallet from Keychain
    /// ⚠️ This is irreversible unless user has backed up seed phrase/private key
    func deleteWallet() async throws
    
    // MARK: - Transaction Signing
    
    /// Sign a Solana transaction
    /// - Parameter transactionData: Unsigned transaction data
    /// - Returns: Signed transaction data
    func signTransaction(transactionData: Data) async throws -> Data
}

// MARK: - Live Implementation

actor LiveWalletService: WalletService {
    
    // MARK: - Dependencies
    
    @Dependency(\.solanaService)
    private var solanaService: SolanaService
    
    // MARK: - Keychain Configuration
    
    private enum KeychainKeys {
        static let privateKeyKey = "com.os.orb.wallet.privateKey"
        static let seedPhraseKey = "com.os.orb.wallet.seedPhrase"
        static let initTimestampKey = "com.os.orb.wallet.initTimestamp"
        static let service = "com.os.orb.wallet"
    }
    
    // MARK: - Cached Keypair
    
    private var cachedKeypair: SolanaSwift.KeyPair?
    
    // MARK: - Wallet Access
    
    func getPublicKey() async throws -> String {
        let keypair = try await getKeypair()
        return keypair.publicKey.base58EncodedString
    }
    
    func getKeypair() async throws -> SolanaSwift.KeyPair {
        // Return cached keypair if available
        if let cached = cachedKeypair {
            return cached
        }
        
        // Try to load from Keychain
        guard let privateKeyData = try loadFromKeychain(key: KeychainKeys.privateKeyKey) else {
            throw WalletServiceError.walletNotFound
        }
        
        // Create keypair from private key
        let keypair = try SolanaSwift.KeyPair(secretKey: privateKeyData)
        
        // Cache it
        cachedKeypair = keypair
        
        print("🔑 WalletService: Loaded keypair from Keychain")
        print("   Address: \(keypair.publicKey.base58EncodedString)")
        
        return keypair
    }
    
    func hasWallet() async -> Bool {
        do {
            return try loadFromKeychain(key: KeychainKeys.privateKeyKey) != nil
        } catch {
            return false
        }
    }
    
    // MARK: - Wallet Management
    
    func createWallet() async throws -> String {
        // Check if wallet already exists
        if await hasWallet() {
            throw WalletServiceError.walletAlreadyExists
        }
        
        // Generate new random wallet with seed phrase
        let mnemonic = try await Mnemonic()
        let keypair = try await SolanaSwift.KeyPair(phrase: mnemonic.phrase, network: .mainnetBeta, derivablePath: .default)
        
        // Store private key in Keychain
        let privateKeyData = Data(keypair.secretKey)
        try saveToKeychain(data: privateKeyData, key: KeychainKeys.privateKeyKey)
        
        // Store seed phrase in Keychain (for export later)
        let seedPhraseString = mnemonic.phrase.joined(separator: " ")
        let seedPhraseData = seedPhraseString.data(using: .utf8)!
        try saveToKeychain(data: seedPhraseData, key: KeychainKeys.seedPhraseKey)
        
        // Cache keypair
        cachedKeypair = keypair
        
        let address = keypair.publicKey.base58EncodedString
        
        print("🔑 WalletService: Created new wallet")
        print("   Address: \(address)")
        print("   Seed phrase stored securely")
        
        return address
    }
    
    func importWallet(seedPhrase: [String]) async throws -> String {
        // Check if wallet already exists
        if await hasWallet() {
            throw WalletServiceError.walletAlreadyExists
        }
        
        // Validate and create keypair from seed phrase
        let keypair = try await SolanaSwift.KeyPair(phrase: seedPhrase, network: .mainnetBeta, derivablePath: .default)
        
        // Store private key in Keychain
        let privateKeyData = Data(keypair.secretKey)
        try saveToKeychain(data: privateKeyData, key: KeychainKeys.privateKeyKey)
        
        // Store seed phrase in Keychain
        let seedPhraseString = seedPhrase.joined(separator: " ")
        let seedPhraseData = seedPhraseString.data(using: .utf8)!
        try saveToKeychain(data: seedPhraseData, key: KeychainKeys.seedPhraseKey)
        
        // Cache keypair
        cachedKeypair = keypair
        
        let address = keypair.publicKey.base58EncodedString
        
        print("🔑 WalletService: Imported wallet from seed phrase")
        print("   Address: \(address)")
        
        return address
    }
    
    func importWallet(privateKey: String) async throws -> String {
        // Check if wallet already exists
        if await hasWallet() {
            throw WalletServiceError.walletAlreadyExists
        }
        
        // Decode base58 private key
        let privateKeyBytes = Base58.decode(privateKey)
        
        guard !privateKeyBytes.isEmpty else {
             throw WalletServiceError.invalidPrivateKey
        }
        
        let privateKeyData = Data(privateKeyBytes)
        
        // Create keypair from private key
        let keypair: SolanaSwift.KeyPair
        do {
            keypair = try SolanaSwift.KeyPair(secretKey: privateKeyData)
        } catch {
            print("Error creating keypair: \(error)")
            throw WalletServiceError.invalidPrivateKey
        }
        
        try saveToKeychain(data: privateKeyData, key: KeychainKeys.privateKeyKey)
        
        // Note: No seed phrase available when importing from private key
        
        // Cache keypair
        cachedKeypair = keypair
        
        let address = keypair.publicKey.base58EncodedString
        
        print("🔑 WalletService: Imported wallet from private key")
        print("   Address: \(address)")
        print("   ⚠️ No seed phrase available for this wallet")
        
        return address
    }
    
    func exportSeedPhrase() async throws -> [String] {
        guard let seedPhraseData = try loadFromKeychain(key: KeychainKeys.seedPhraseKey),
              let seedPhraseString = String(data: seedPhraseData, encoding: .utf8) else {
            throw WalletServiceError.seedPhraseNotAvailable
        }
        
        let seedPhrase = seedPhraseString.split(separator: " ").map(String.init)
        
        print("⚠️ WalletService: Seed phrase exported")
        print("   This is sensitive data - handle with care!")
        
        return seedPhrase
    }
    
    func exportPrivateKey() async throws -> String {
        let keypair = try await getKeypair()
        let privateKeyBase58 = Base58.encode(keypair.secretKey)
        
        print("⚠️ WalletService: Private key exported")
        print("   This is EXTREMELY sensitive data - handle with care!")
        
        return privateKeyBase58
    }
    
    func deleteWallet() async throws {
        // Delete from Keychain
        try deleteFromKeychain(key: KeychainKeys.privateKeyKey)
        try? deleteFromKeychain(key: KeychainKeys.seedPhraseKey) // May not exist
        try? deleteFromKeychain(key: KeychainKeys.initTimestampKey) // May not exist
        
        // Clear cache
        cachedKeypair = nil
        
        print("🔑 WalletService: Wallet deleted from Keychain")
        print("   ⚠️ This action is irreversible!")
    }
    
    // MARK: - Transaction Signing
    
    func signTransaction(transactionData: Data) async throws -> Data {
        print("🔑 WalletService: Signing transaction...")
        
        // Get keypair for signing
        let keypair = try await getKeypair()
        
        // Deserialize the transaction (Jupiter uses versioned transactions)
        var transaction = try SolanaSwift.VersionedTransaction.deserialize(data: transactionData)
        
        print("   Signing with wallet: \(keypair.publicKey.base58EncodedString)")
        
        // Sign the transaction
        try transaction.sign(signers: [keypair])
        
        // Serialize the signed transaction
        let signedTransactionData = try transaction.serialize()
        
        print("   ✅ Transaction signed (\(signedTransactionData.count) bytes)")
        
        return signedTransactionData
    }
    
    func getInitializationTimestamp() async -> Int? {
        guard let data = try? loadFromKeychain(key: KeychainKeys.initTimestampKey),
              let timestampString = String(data: data, encoding: .utf8),
              let timestamp = Int(timestampString) else {
            return nil
        }
        return timestamp
    }
    
    func setInitializationTimestamp(_ timestamp: Int) async throws {
        let timestampString = String(timestamp)
        let data = timestampString.data(using: .utf8)!
        try saveToKeychain(data: data, key: KeychainKeys.initTimestampKey)
        print("🔑 WalletService: Initialization timestamp set: \(timestamp)")
    }
    
    // MARK: - Keychain Operations
    
    private func saveToKeychain(data: Data, key: String) throws {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: KeychainKeys.service,
            kSecAttrAccount as String: key,
            kSecValueData as String: data,
            kSecAttrAccessible as String: kSecAttrAccessibleWhenUnlockedThisDeviceOnly
        ]
        
        // Delete any existing item
        SecItemDelete(query as CFDictionary)
        
        // Add new item
        let status = SecItemAdd(query as CFDictionary, nil)
        
        guard status == errSecSuccess else {
            throw WalletServiceError.keychainError(status: status)
        }
    }
    
    private func loadFromKeychain(key: String) throws -> Data? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: KeychainKeys.service,
            kSecAttrAccount as String: key,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        
        if status == errSecItemNotFound {
            return nil
        }
        
        guard status == errSecSuccess else {
            throw WalletServiceError.keychainError(status: status)
        }
        
        return result as? Data
    }
    
    private func deleteFromKeychain(key: String) throws {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: KeychainKeys.service,
            kSecAttrAccount as String: key
        ]
        
        let status = SecItemDelete(query as CFDictionary)
        
        // It's okay if the item doesn't exist
        guard status == errSecSuccess || status == errSecItemNotFound else {
            throw WalletServiceError.keychainError(status: status)
        }
    }
}

// MARK: - Errors

enum WalletServiceError: Error, LocalizedError {
    case walletNotFound
    case walletAlreadyExists
    case invalidPrivateKey
    case invalidSeedPhrase
    case seedPhraseNotAvailable
    case keychainError(status: OSStatus)
    
    var errorDescription: String? {
        switch self {
        case .walletNotFound:
            return "No wallet found. Please create or import a wallet first."
        case .walletAlreadyExists:
            return "A wallet already exists. Please delete it first if you want to create a new one."
        case .invalidPrivateKey:
            return "Cannot recover account. Please check that your private key is correct."
        case .invalidSeedPhrase:
            return "Invalid seed phrase. Please check the words and try again."
        case .seedPhraseNotAvailable:
            return "Seed phrase not available for this wallet. It may have been imported using a private key."
        case .keychainError(let status):
            return "Keychain error (status: \(status)). Please try again."
        }
    }
}

// MARK: - Dependency Registration

extension DependencyValues {
    var walletService: WalletService {
        get { self[WalletServiceKey.self] }
        set { self[WalletServiceKey.self] = newValue }
    }
}

private enum WalletServiceKey: DependencyKey {
    static let liveValue: WalletService = LiveWalletService()
    static let testValue: WalletService = { preconditionFailure() }()
}

