import Foundation
import Starscream

public final class OrbIntelBuilder: Sendable {
    
    // MARK: - Static
    
    public static let shared = OrbIntelBuilder()
    
    // MARK: - Init
    
    private init() {}
    
    // MARK: Methods
    
    public func build(
        url: URL,
        webSocketUrl: URL,
        apiKey: String,
        publicKey: String,
        network: OrbNetwork,
        session: URLSession = .shared
    ) throws -> OrbIntel {
        
        let requestBuilder = URLRequestBuilder()
        
        let request = try requestBuilder.createURLRequest(
            for: OrbAPI.connect(apiKey: apiKey),
            baseURL: webSocketUrl,
            defaultHeaders: [:]
        )
        
        let apiService = LiveOrbAPIService(
            networkClient: NetworkClient(
                configuration: NetworkConfiguration(
                    baseURL: url
                ),
                session: session,
                requestBuilder: requestBuilder
            )
        )
        
        return OrbIntel(
            apiKey: apiKey,
            publicKey: publicKey,
            network: network,
            apiService: apiService,
            webSocket: WebSocket(request: request),
            eventDecoder: LiveOrbEventDecoder(
                decoder: JSONDecoder(),
                isLoggingEnabled: false
            ),
            eventEncoder: LiveOrbEventEncoder(
                encoder: JSONEncoder()
            )
        )
    }
}
