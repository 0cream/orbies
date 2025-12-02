import Dependencies
import Foundation

protocol APIAuthorizedClientService: Sendable {
    func request<T>(_ closure: @Sendable @escaping (String) async throws -> T) async throws -> T
}

actor LiveAPIAuthorizedClientService: APIAuthorizedClientService {
    
    // MARK: - Dependencies
    
    @DependencyMacro(\.privyService)
    private var privyService: PrivyService
    
    // MARK: - Methods
    
    func request<T: Sendable>(_ closure: @Sendable @escaping (String) async throws -> T) async throws -> T {
        // let token = try await privyService.client.accessToken() // check Privy API
        let token: String = {
            fatalError("Get token from Privy service")
        }()
        
        let response = try await closure(token)
        
        return response
    }
}

extension DependencyValues {
    var apiAuthorizedClientService: APIAuthorizedClientService {
        get { self[APIAuthorizedClientServiceKey.self] }
        set { self[APIAuthorizedClientServiceKey.self] = newValue }
    }
}

private enum APIAuthorizedClientServiceKey: DependencyKey {
    static let liveValue: APIAuthorizedClientService = LiveAPIAuthorizedClientService()
    static let testValue: APIAuthorizedClientService = { preconditionFailure() }()
}

