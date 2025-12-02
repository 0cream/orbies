import Dependencies
import Foundation
import OpenAPIClient

protocol APIClientService: Sendable {
    func setup() async throws 
}

actor LiveAPIClientService: APIClientService {
    enum Constants {
        static let basePath = "https://orb-invest-backend.onrender.com"
    }
    
    func setup() async throws {
        OpenAPIClientAPIConfiguration.shared.basePath = Constants.basePath
    }
}

extension DependencyValues {
    var apiClientService: APIClientService {
        get { self[APIClientServiceKey.self] }
        set { self[APIClientServiceKey.self] = newValue }
    }
}

private enum APIClientServiceKey: DependencyKey {
    static let liveValue: APIClientService = LiveAPIClientService()
    static let testValue: APIClientService = { preconditionFailure() }()
}

