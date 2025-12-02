protocol OrbAPIService {
    func initialize(parameters: OrbInitializeRequestBody) async throws
}

public final class LiveOrbAPIService: OrbAPIService {
    
    // MARK: - Private Properties
    
    private let networkClient: NetworkClient
    
    // MARK: - Init
    
    init(networkClient: NetworkClient) {
        self.networkClient = networkClient
    }
    
    // MARK: - Methods
    
    func initialize(parameters: OrbInitializeRequestBody) async throws {
        _ = try await networkClient.execute(
            OrbAPI.initialize(parameters: parameters)
        )
    }
}
