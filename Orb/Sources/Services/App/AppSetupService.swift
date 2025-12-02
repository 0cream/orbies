import Dependencies
import Foundation

protocol AppSetupService: Sendable {
    func setup() async throws
}

actor LiveAppSetupService: AppSetupService {
    
    // MARK: - Dependencies
    
    @Dependency(\.privyService)
    private var privyService: PrivyService
    
    @Dependency(\.apiClientService)
    private var apiClientService: APIClientService
    
    @Dependency(\.userService)
    private var userService: UserService
    
    @Dependency(\.priceHistoryService)
    private var priceHistoryService: PriceHistoryService
    
    @Dependency(\.jupiterService)
    private var jupiterService: JupiterService
    
    // MARK: - Methods
    
    func setup() async throws {
        try await privyService.setup()
        try await apiClientService.setup()
        
        // Fetch Jupiter verified tokens list (critical for filtering)
        try await jupiterService.setup()
        
        try await userService.setup()
        await priceHistoryService.setup() // Generate price histories first
    }
}

// MARK: - Dependency

extension DependencyValues {
    var appSetupService: AppSetupService {
        get { self[AppSetupServiceKey.self] }
        set { self[AppSetupServiceKey.self] = newValue }
    }
}

private enum AppSetupServiceKey: DependencyKey {
    static let liveValue: AppSetupService = LiveAppSetupService()
    static let testValue: AppSetupService = { preconditionFailure() }()
}

