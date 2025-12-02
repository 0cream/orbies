import Dependencies
import Foundation

protocol AuthService: Actor {
    
    // MARK: - Properties
    
    var user: User? { get async }
    var userStream: AsyncStream<User?> { get async }
    var authState: AuthState { get async throws }
    var authStateStream: AsyncStream<AuthState> { get async }
    
    // MARK: - Methods
    
    func setup() async throws
    func auth(with provider: AuthProvider) async throws
}

actor LiveAuthService: AuthService {
    
    // MARK: - Internal Properties
    
    var user: User? {
        get async {
            await userPublisher.lastValue ?? nil
        }
    }
    
    var userStream: AsyncStream<User?> {
        get async {
            await userPublisher.stream()
        }
    }
    
    var authState: AuthState {
        get async throws {
            try await privyService.client.getAuthState().asLocalAuthState
        }
    }
    
    var authStateStream: AsyncStream<AuthState> {
        get async {
            await privyService.client.authStateStream
                .compactMap { try? $0.asLocalAuthState }
                .eraseToStream()
        }
    }
    
    // MARK: - Dependencies
    
    @DependencyMacro(\.privyService)
    private var privyService: PrivyService
    
    // MARK: - Private Properties
    
    private var authObserverTask: Task<Void, Never>?
    private let userPublisher = AsyncPublisher<User?>()
    
    // MARK: - Methods
    
    func setup() async throws {
        authObserverTask = Task.detached { [weak self] in
            await self?.setupAuthStateObserver()
        }
    }
    
    func auth(with provider: AuthProvider) async throws {
        print("✅ User successfully authorized with '\(provider.rawValue)' and id: '\(1)'")
    }
    
    func accessToken() async throws -> String? {
        guard let user = await privyService.client.getUser() else {
            return nil
        }
        
        return try await user.getAccessToken()
    }
    
    private func setupAuthStateObserver() async {
        for await authState in await privyService.client.authStateStream {
            switch authState {
            case let .authenticated(user):
                await userPublisher.publish(
                    User(
                        id: user.id,
                        wallets: user.embeddedSolanaWallets.map { solanaWallet in
                            UserWallet(
                                address: solanaWallet.address,
                                network: .solana
                            )
                        },
                        createdAt: user.createdAt
                    )
                )
                
            case .authenticatedUnverified, .notReady, .unauthenticated:
                await userPublisher.publish(nil)
                
            @unknown default:
                await userPublisher.publish(nil)
            }
        }
    }
}

// MARK: - Dependency

extension DependencyValues {
    var authService: AuthService {
        get { self[AuthServiceKey.self] }
        set { self[AuthServiceKey.self] = newValue }
    }
}

private enum AuthServiceKey: DependencyKey {
    static let liveValue: AuthService = LiveAuthService()
    static let testValue: AuthService = { preconditionFailure() }()
}
