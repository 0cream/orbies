import Dependencies
import Foundation
import PrivySDK

// MARK: - PrivyService Protocol

/// Service for managing Privy authentication and embedded wallets
/// Provides a centralized interface for all Privy SDK operations
protocol PrivyService: Actor {
    
    // MARK: - Properties
    
    /// The underlying Privy SDK client instance
    /// Access this for direct SDK calls if needed
    var client: Privy { get }
    
    // MARK: - Setup
    
    /// Initialize the Privy SDK with configuration
    /// Must be called during app setup before any other Privy operations
    /// - Throws: PrivyError if initialization fails
    func setup() async throws
    
    // MARK: - Authentication State
    
    /// Get the current authentication state
    /// - Returns: Current AuthState (notReady, unauthenticated, authenticated, etc.)
    func getAuthState() async -> PrivySDK.AuthState
    
    /// Get the currently authenticated user, if any
    /// - Returns: PrivyUser if authenticated, nil otherwise
    func getUser() async -> PrivySDK.PrivyUser?
    
    /// Stream of authentication state changes
    /// Use this to reactively update UI based on auth state
    /// - Returns: AsyncStream that emits AuthState updates
    func authStateStream() -> AsyncStream<PrivySDK.AuthState>
    
    // MARK: - OAuth Authentication
    
    /// Login with Google OAuth
    /// Opens system browser for authentication flow
    /// - Parameter appUrlScheme: URL scheme for callback (e.g., "yourapp://")
    /// - Returns: Authenticated PrivyUser
    /// - Throws: PrivyError if login fails or is cancelled
    func loginWithGoogle(appUrlScheme: String?) async throws -> PrivySDK.PrivyUser
    
    /// Login with Apple OAuth
    /// Uses native Apple Sign In
    /// - Parameter appUrlScheme: URL scheme for callback (optional)
    /// - Returns: Authenticated PrivyUser
    /// - Throws: PrivyError if login fails or is cancelled
    func loginWithApple(appUrlScheme: String?) async throws -> PrivySDK.PrivyUser
    
    /// Login with Twitter OAuth
    /// Opens system browser for Twitter authentication
    /// - Parameter appUrlScheme: URL scheme for callback
    /// - Returns: Authenticated PrivyUser
    /// - Throws: PrivyError if login fails or is cancelled
    func loginWithTwitter(appUrlScheme: String?) async throws -> PrivySDK.PrivyUser
    
    /// Login with Discord OAuth
    /// Opens system browser for Discord authentication
    /// - Parameter appUrlScheme: URL scheme for callback
    /// - Returns: Authenticated PrivyUser
    /// - Throws: PrivyError if login fails or is cancelled
    func loginWithDiscord(appUrlScheme: String?) async throws -> PrivySDK.PrivyUser
    
    /// Generic OAuth login with any supported provider
    /// - Parameters:
    ///   - provider: OAuth provider to use (.google, .apple, .twitter, .discord)
    ///   - appUrlScheme: URL scheme for callback
    /// - Returns: Authenticated PrivyUser
    /// - Throws: PrivyError if login fails
    func loginWithOAuth(provider: PrivySDK.OAuthProvider, appUrlScheme: String?) async throws -> PrivySDK.PrivyUser
    
    // MARK: - Email Authentication
    
    /// Send verification code to email address
    /// User will receive an email with a 6-digit code
    /// - Parameter email: Email address to send code to
    /// - Throws: PrivyError if sending fails
    func sendEmailCode(to email: String) async throws
    
    /// Login using email verification code
    /// - Parameters:
    ///   - code: 6-digit verification code from email
    ///   - email: Email address where code was sent
    /// - Returns: Authenticated PrivyUser
    /// - Throws: PrivyError if code is invalid or expired
    func loginWithEmailCode(_ code: String, sentTo email: String) async throws -> PrivySDK.PrivyUser
    
    /// Link email to existing authenticated user
    /// - Parameters:
    ///   - code: 6-digit verification code from email
    ///   - email: Email address to link
    /// - Throws: PrivyError if code is invalid or user not authenticated
    func linkEmailWithCode(_ code: String, sentTo email: String) async throws
    
    /// Update user's email address
    /// - Parameters:
    ///   - code: 6-digit verification code from new email
    ///   - email: New email address
    /// - Throws: PrivyError if code is invalid or user not authenticated
    func updateEmailWithCode(_ code: String, sentTo email: String) async throws
    
    // MARK: - SMS Authentication
    
    /// Send verification code to phone number
    /// User will receive an SMS with a 6-digit code
    /// - Parameter phoneNumber: Phone number in E.164 format (e.g., "+1234567890")
    /// - Throws: PrivyError if sending fails
    func sendSmsCode(to phoneNumber: String) async throws
    
    /// Login using SMS verification code
    /// - Parameters:
    ///   - code: 6-digit verification code from SMS
    ///   - phoneNumber: Phone number where code was sent
    /// - Returns: Authenticated PrivyUser
    /// - Throws: PrivyError if code is invalid or expired
    func loginWithSmsCode(_ code: String, sentTo phoneNumber: String) async throws -> PrivySDK.PrivyUser
    
    /// Link phone number to existing authenticated user
    /// - Parameters:
    ///   - code: 6-digit verification code from SMS
    ///   - phoneNumber: Phone number to link
    /// - Throws: PrivyError if code is invalid or user not authenticated
    func linkSmsWithCode(_ code: String, sentTo phoneNumber: String) async throws
    
    /// Update user's phone number
    /// - Parameters:
    ///   - code: 6-digit verification code from new phone
    ///   - phoneNumber: New phone number
    /// - Throws: PrivyError if code is invalid or user not authenticated
    func updateSmsWithCode(_ code: String, sentTo phoneNumber: String) async throws
    
    // MARK: - SIWE (Sign-In With Ethereum)
    
    /// Generate SIWE (Sign-In with Ethereum) message for signing
    /// - Parameter params: SIWE message parameters (domain, URI, chainId, address)
    /// - Returns: Formatted SIWE message string to be signed by wallet
    /// - Throws: PrivyError if message generation fails
    func generateSiweMessage(params: PrivySDK.SiweMessageParams) async throws -> String
    
    /// Login using signed SIWE message
    /// - Parameters:
    ///   - message: SIWE message that was signed
    ///   - signature: Signature from wallet
    ///   - params: SIWE parameters used for message generation
    ///   - metadata: Optional wallet metadata (client type, connector)
    /// - Returns: Authenticated PrivyUser
    /// - Throws: PrivyError if signature verification fails
    func loginWithSiwe(message: String, signature: String, params: PrivySDK.SiweMessageParams, metadata: PrivySDK.WalletLoginMetadata?) async throws -> PrivySDK.PrivyUser
    
    // MARK: - Custom JWT Authentication
    
    /// Login using custom JWT token from your backend
    /// Requires custom auth configuration in PrivyConfig
    /// - Returns: Authenticated PrivyUser
    /// - Throws: PrivyError if token is invalid or custom auth not configured
    func loginWithCustomJwt() async throws -> PrivySDK.PrivyUser
    
    // MARK: - Wallet Management
    
    /// Get all Solana embedded wallets for the current user
    /// - Returns: Array of embedded Solana wallets (may be empty)
    func getSolanaWallets() async -> [PrivySDK.EmbeddedSolanaWallet]
    
    /// Get the primary (first) Solana wallet address, if available
    /// - Returns: Solana wallet address string, or nil if no wallet exists
    func getPrimarySolanaAddress() async -> String?
    
    /// Create a new Solana embedded wallet for the current user
    /// - Parameters:
    ///   - allowAdditional: Whether to allow creating additional wallets
    ///   - timeout: Max time to wait for wallet creation
    /// - Returns: Newly created EmbeddedSolanaWallet
    /// - Throws: PrivyError if wallet creation fails or user not authenticated
    func createSolanaWallet(allowAdditional: Bool, timeout: Duration) async throws -> PrivySDK.EmbeddedSolanaWallet
    
    /// Get all Ethereum embedded wallets for the current user
    /// - Returns: Array of embedded Ethereum wallets (may be empty)
    func getEthereumWallets() async -> [PrivySDK.EmbeddedEthereumWallet]
    
    /// Create a new Ethereum embedded wallet for the current user
    /// - Parameters:
    ///   - allowAdditional: Whether to allow creating additional wallets
    ///   - timeout: Max time to wait for wallet creation
    /// - Returns: Newly created EmbeddedEthereumWallet
    /// - Throws: PrivyError if wallet creation fails or user not authenticated
    func createEthereumWallet(allowAdditional: Bool, timeout: Duration) async throws -> PrivySDK.EmbeddedEthereumWallet
    
    // MARK: - Wallet Signing Operations
    
    /// Sign a message with Solana wallet
    /// ⚠️ NOTE: This only SIGNS the message. You need to submit it to Solana RPC yourself.
    /// - Parameters:
    ///   - message: Message string to sign
    ///   - wallet: Solana wallet to use for signing (or primary if nil)
    /// - Returns: Base58-encoded signature
    /// - Throws: PrivyError if signing fails or wallet not found
    func signSolanaMessage(_ message: String, wallet: PrivySDK.EmbeddedSolanaWallet?) async throws -> String
    
    /// Execute Ethereum RPC request (signing or sending transactions)
    /// Supports: personal_sign, eth_sign, eth_signTypedData_v4, eth_signTransaction, eth_sendTransaction
    /// - Parameters:
    ///   - request: Ethereum RPC request (use static methods on EthereumRpcRequest)
    ///   - wallet: Ethereum wallet to use (or primary if nil)
    /// - Returns: JSON-RPC response string (signature or transaction hash)
    /// - Throws: PrivyError if request fails or wallet not found
    func executeEthereumRequest(_ request: PrivySDK.EthereumRpcRequest, wallet: PrivySDK.EmbeddedEthereumWallet?) async throws -> String
    
    /// Sign Ethereum transaction (does NOT send to network)
    /// Returns the signed transaction that you can broadcast yourself
    /// - Parameters:
    ///   - transaction: Unsigned transaction parameters
    ///   - wallet: Ethereum wallet to use (or primary if nil)
    /// - Returns: Signed transaction data as hex string
    /// - Throws: PrivyError if signing fails
    func signEthereumTransaction(_ transaction: PrivySDK.EthereumRpcRequest.UnsignedEthTransaction, wallet: PrivySDK.EmbeddedEthereumWallet?) async throws -> String
    
    /// Sign AND send Ethereum transaction to network
    /// ✅ This signs and broadcasts the transaction in one call
    /// - Parameters:
    ///   - transaction: Unsigned transaction parameters
    ///   - wallet: Ethereum wallet to use (or primary if nil)
    /// - Returns: Transaction hash
    /// - Throws: PrivyError if signing or sending fails
    func sendEthereumTransaction(_ transaction: PrivySDK.EthereumRpcRequest.UnsignedEthTransaction, wallet: PrivySDK.EmbeddedEthereumWallet?) async throws -> String
    
    /// Sign a personal message with Ethereum wallet (EIP-191)
    /// - Parameters:
    ///   - message: Message string to sign
    ///   - wallet: Ethereum wallet to use (or primary if nil)
    /// - Returns: Signature as hex string
    /// - Throws: PrivyError if signing fails
    func signEthereumPersonalMessage(_ message: String, wallet: PrivySDK.EmbeddedEthereumWallet?) async throws -> String
    
    /// Sign typed data with Ethereum wallet (EIP-712)
    /// - Parameters:
    ///   - typedData: Structured data to sign
    ///   - wallet: Ethereum wallet to use (or primary if nil)
    /// - Returns: Signature as hex string
    /// - Throws: PrivyError if signing fails
    func signEthereumTypedData(_ typedData: PrivySDK.EthereumRpcRequest.EIP712TypedData, wallet: PrivySDK.EmbeddedEthereumWallet?) async throws -> String
    
    /// Get current chain ID for Ethereum wallet
    /// - Parameter wallet: Ethereum wallet (or primary if nil)
    /// - Returns: Chain ID (e.g., 1 for mainnet, 11155111 for Sepolia)
    func getEthereumChainId(wallet: PrivySDK.EmbeddedEthereumWallet?) async throws -> Int
    
    /// Switch Ethereum wallet to different chain
    /// - Parameters:
    ///   - chainId: Target chain ID
    ///   - rpcUrl: Optional custom RPC URL for the chain
    ///   - wallet: Ethereum wallet to switch (or primary if nil)
    func switchEthereumChain(chainId: Int, rpcUrl: String?, wallet: PrivySDK.EmbeddedEthereumWallet?) async throws
    
    // MARK: - User Management
    
    /// Get access token for the current authenticated user
    /// Used for backend API calls that require authentication
    /// - Returns: JWT access token string
    /// - Throws: PrivyError if user not authenticated or token generation fails
    func getAccessToken() async throws -> String
    
    /// Refresh user data from Privy servers
    /// Call this to sync latest user state (wallets, linked accounts, etc.)
    /// - Throws: PrivyError if refresh fails or user not authenticated
    func refreshUser() async throws
    
    /// Logout the current user
    /// Clears all local session data and revokes tokens
    func logout() async
    
    // MARK: - Network
    
    /// Notify Privy SDK that network connectivity has been restored
    /// Call this when app detects network is back online after being offline
    func onNetworkRestored() async
}

// MARK: - Live Implementation

actor LivePrivyService: PrivyService {
    
    // MARK: - Configuration
    
    enum Constants {
        /// Privy app configuration
        /// App ID and Client ID are provided by Privy Dashboard
        static let config = PrivyConfig(
            appId: "cmh4yn4nk029fky0deplsqlfr",
            appClientId: "3j1sPCiX7RpdfHoS9iX4i8e79PNASNFP37VxPeUfSpzWsUVKw5VavhAqn5bzQ5ab4fUL3Wi3rr6YUagLrDDdXhYZ",
            loggingConfig: .init(
                logLevel: .verbose // Enable verbose logging for debugging
            )
        )
    }
    
    // MARK: - Properties
    
    /// The Privy SDK client instance
    /// Initialized in setup()
    @Required
    private(set) var client: PrivySDK.Privy
    
    // MARK: - Setup
    
    func setup() async throws {
        // TODO: Fix webview handler issue
        // Currently disabled due to webview initialization problems
        // client = PrivySdk.initialize(config: Constants.config)
        print("🔐 PrivyService: Setup attempted (currently disabled due to webview issue)")
    }
    
    // MARK: - Authentication State
    
    func getAuthState() async -> PrivySDK.AuthState {
        await client.getAuthState()
    }
    
    func getUser() async -> PrivySDK.PrivyUser? {
        await client.getUser()
    }
    
    func authStateStream() -> AsyncStream<PrivySDK.AuthState> {
        client.authStateStream
    }
    
    // MARK: - OAuth Authentication
    
    func loginWithGoogle(appUrlScheme: String?) async throws -> PrivySDK.PrivyUser {
        try await client.oAuth.login(with: .google, appUrlScheme: appUrlScheme)
    }
    
    func loginWithApple(appUrlScheme: String?) async throws -> PrivySDK.PrivyUser {
        try await client.oAuth.login(with: .apple, appUrlScheme: appUrlScheme)
    }
    
    func loginWithTwitter(appUrlScheme: String?) async throws -> PrivySDK.PrivyUser {
        try await client.oAuth.login(with: .twitter, appUrlScheme: appUrlScheme)
    }
    
    func loginWithDiscord(appUrlScheme: String?) async throws -> PrivySDK.PrivyUser {
        try await client.oAuth.login(with: .discord, appUrlScheme: appUrlScheme)
    }
    
    func loginWithOAuth(provider: PrivySDK.OAuthProvider, appUrlScheme: String?) async throws -> PrivySDK.PrivyUser {
        try await client.oAuth.login(with: provider, appUrlScheme: appUrlScheme)
    }
    
    // MARK: - Email Authentication
    
    func sendEmailCode(to email: String) async throws {
        try await client.email.sendCode(to: email)
    }
    
    func loginWithEmailCode(_ code: String, sentTo email: String) async throws -> PrivySDK.PrivyUser {
        try await client.email.loginWithCode(code, sentTo: email)
    }
    
    func linkEmailWithCode(_ code: String, sentTo email: String) async throws {
        try await client.email.linkWithCode(code, sentTo: email)
    }
    
    func updateEmailWithCode(_ code: String, sentTo email: String) async throws {
        try await client.email.updateWithCode(code, sentTo: email)
    }
    
    // MARK: - SMS Authentication
    
    func sendSmsCode(to phoneNumber: String) async throws {
        try await client.sms.sendCode(to: phoneNumber)
    }
    
    func loginWithSmsCode(_ code: String, sentTo phoneNumber: String) async throws -> PrivySDK.PrivyUser {
        try await client.sms.loginWithCode(code, sentTo: phoneNumber)
    }
    
    func linkSmsWithCode(_ code: String, sentTo phoneNumber: String) async throws {
        try await client.sms.linkWithCode(code, sentTo: phoneNumber)
    }
    
    func updateSmsWithCode(_ code: String, sentTo phoneNumber: String) async throws {
        try await client.sms.updateWithCode(code, sentTo: phoneNumber)
    }
    
    // MARK: - SIWE (Sign-In With Ethereum)
    
    func generateSiweMessage(params: PrivySDK.SiweMessageParams) async throws -> String {
        try await client.siwe.generateSiweMessage(params: params)
    }
    
    func loginWithSiwe(message: String, signature: String, params: PrivySDK.SiweMessageParams, metadata: PrivySDK.WalletLoginMetadata?) async throws -> PrivySDK.PrivyUser {
        try await client.siwe.loginWithSiwe(message: message, signature: signature, params: params, metadata: metadata)
    }
    
    // MARK: - Custom JWT Authentication
    
    func loginWithCustomJwt() async throws -> PrivySDK.PrivyUser {
        try await client.customJwt.loginWithCustomAccessToken()
    }
    
    // MARK: - Wallet Management
    
    func getSolanaWallets() async -> [PrivySDK.EmbeddedSolanaWallet] {
        guard let user = await getUser() else { return [] }
        return user.embeddedSolanaWallets
    }
    
    func getPrimarySolanaAddress() async -> String? {
        await getSolanaWallets().first?.address
    }
    
    func createSolanaWallet(allowAdditional: Bool = false, timeout: Duration = .seconds(30)) async throws -> PrivySDK.EmbeddedSolanaWallet {
        guard let user = await getUser() else {
            throw PrivyServiceError.userNotAuthenticated
        }
        return try await user.createSolanaWallet(allowAdditional: allowAdditional, timeout: timeout)
    }
    
    func getEthereumWallets() async -> [PrivySDK.EmbeddedEthereumWallet] {
        guard let user = await getUser() else { return [] }
        return user.embeddedEthereumWallets
    }
    
    func createEthereumWallet(allowAdditional: Bool = false, timeout: Duration = .seconds(30)) async throws -> PrivySDK.EmbeddedEthereumWallet {
        guard let user = await getUser() else {
            throw PrivyServiceError.userNotAuthenticated
        }
        return try await user.createEthereumWallet(allowAdditional: allowAdditional, timeout: timeout)
    }
    
    // MARK: - Wallet Signing Operations
    
    func signSolanaMessage(_ message: String, wallet: PrivySDK.EmbeddedSolanaWallet?) async throws -> String {
        let targetWallet: PrivySDK.EmbeddedSolanaWallet?
        if let wallet = wallet {
            targetWallet = wallet
        } else {
            targetWallet = await getSolanaWallets().first
        }
        
        guard let targetWallet else {
            throw PrivyServiceError.walletNotFound
        }
        return try await targetWallet.provider.signMessage(message: message)
    }
    
    func executeEthereumRequest(_ request: PrivySDK.EthereumRpcRequest, wallet: PrivySDK.EmbeddedEthereumWallet?) async throws -> String {
        let targetWallet: PrivySDK.EmbeddedEthereumWallet?
        if let wallet = wallet {
            targetWallet = wallet
        } else {
            targetWallet = await getEthereumWallets().first
        }
        
        guard let targetWallet else {
            throw PrivyServiceError.walletNotFound
        }
        return try await targetWallet.provider.request(request)
    }
    
    func signEthereumTransaction(_ transaction: PrivySDK.EthereumRpcRequest.UnsignedEthTransaction, wallet: PrivySDK.EmbeddedEthereumWallet?) async throws -> String {
        let request = try PrivySDK.EthereumRpcRequest.ethSignTransaction(transaction: transaction)
        return try await executeEthereumRequest(request, wallet: wallet)
    }
    
    func sendEthereumTransaction(_ transaction: PrivySDK.EthereumRpcRequest.UnsignedEthTransaction, wallet: PrivySDK.EmbeddedEthereumWallet?) async throws -> String {
        let request = try PrivySDK.EthereumRpcRequest.ethSendTransaction(transaction: transaction)
        return try await executeEthereumRequest(request, wallet: wallet)
    }
    
    func signEthereumPersonalMessage(_ message: String, wallet: PrivySDK.EmbeddedEthereumWallet?) async throws -> String {
        let targetWallet: PrivySDK.EmbeddedEthereumWallet?
        if let wallet = wallet {
            targetWallet = wallet
        } else {
            targetWallet = await getEthereumWallets().first
        }
        
        guard let address = targetWallet?.address else {
            throw PrivyServiceError.walletNotFound
        }
        let request = PrivySDK.EthereumRpcRequest.personalSign(message: message, address: address)
        return try await executeEthereumRequest(request, wallet: wallet)
    }
    
    func signEthereumTypedData(_ typedData: PrivySDK.EthereumRpcRequest.EIP712TypedData, wallet: PrivySDK.EmbeddedEthereumWallet?) async throws -> String {
        let targetWallet: PrivySDK.EmbeddedEthereumWallet?
        if let wallet = wallet {
            targetWallet = wallet
        } else {
            targetWallet = await getEthereumWallets().first
        }
        
        guard let address = targetWallet?.address else {
            throw PrivyServiceError.walletNotFound
        }
        let request = try PrivySDK.EthereumRpcRequest.ethSignTypedDataV4(address: address, typedData: typedData)
        return try await executeEthereumRequest(request, wallet: wallet)
    }
    
    func getEthereumChainId(wallet: PrivySDK.EmbeddedEthereumWallet?) async throws -> Int {
        let targetWallet: PrivySDK.EmbeddedEthereumWallet?
        if let wallet = wallet {
            targetWallet = wallet
        } else {
            targetWallet = await getEthereumWallets().first
        }
        
        guard let targetWallet else {
            throw PrivyServiceError.walletNotFound
        }
        return await targetWallet.provider.chainId
    }
    
    func switchEthereumChain(chainId: Int, rpcUrl: String?, wallet: PrivySDK.EmbeddedEthereumWallet?) async throws {
        let targetWallet: PrivySDK.EmbeddedEthereumWallet?
        if let wallet = wallet {
            targetWallet = wallet
        } else {
            targetWallet = await getEthereumWallets().first
        }
        
        guard let targetWallet else {
            throw PrivyServiceError.walletNotFound
        }
        await targetWallet.provider.switchChain(chainId: chainId, rpcUrl: rpcUrl)
    }
    
    // MARK: - User Management
    
    func getAccessToken() async throws -> String {
        guard let user = await getUser() else {
            throw PrivyServiceError.userNotAuthenticated
        }
        return try await user.getAccessToken()
    }
    
    func refreshUser() async throws {
        guard let user = await getUser() else {
            throw PrivyServiceError.userNotAuthenticated
        }
        try await user.refresh()
    }
    
    func logout() async {
        guard let user = await getUser() else { return }
        await user.logout()
        print("🔐 PrivyService: User logged out")
    }
    
    // MARK: - Network
    
    func onNetworkRestored() async {
        await client.onNetworkRestored()
    }
}

// MARK: - Errors

/// Custom errors for PrivyService operations
enum PrivyServiceError: Error, LocalizedError {
    case userNotAuthenticated
    case walletCreationFailed
    case walletNotFound
    case tokenGenerationFailed
    case signingFailed
    
    var errorDescription: String? {
        switch self {
        case .userNotAuthenticated:
            return "User is not authenticated. Please login first."
        case .walletCreationFailed:
            return "Failed to create embedded wallet."
        case .walletNotFound:
            return "No wallet found. Please create a wallet first."
        case .tokenGenerationFailed:
            return "Failed to generate access token."
        case .signingFailed:
            return "Failed to sign message or transaction."
        }
    }
}

// MARK: - Dependency Registration

extension DependencyValues {
    /// Injected PrivyService dependency
    /// Access via @Dependency(\.privyService) in reducers/services
    var privyService: PrivyService {
        get { self[PrivyServiceKey.self] }
        set { self[PrivyServiceKey.self] = newValue }
    }
}

private enum PrivyServiceKey: DependencyKey {
    /// Live implementation used in production
    static let liveValue: PrivyService = LivePrivyService()
    
    /// Test implementation - crashes if accessed without explicit mock
    /// Override in tests with your own mock implementation
    static let testValue: PrivyService = { preconditionFailure() }()
}
