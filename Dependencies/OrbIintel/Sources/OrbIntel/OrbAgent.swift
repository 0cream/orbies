import Foundation
import Starscream

public final class OrbIntel {

    // MARK: - Dependencies
    
    private let apiService: OrbAPIService
    private let webSocket: WebSocket
    private let eventDecoder: OrbEventDecoder
    private let eventEncoder: OrbEventEncoder
    
    // MARK: - Private Properties
    
    private let apiKey: String
    private let publicKey: String
    private let network: OrbNetwork
    
    // MARK: - Mutable Properties
    
    private var isInitialized = false
    
    // MARK: - Init
    
    init(
        apiKey: String,
        publicKey: String,
        network: OrbNetwork,
        apiService: OrbAPIService,
        webSocket: WebSocket,
        eventDecoder: OrbEventDecoder,
        eventEncoder: OrbEventEncoder
    ) {
        self.apiKey = apiKey
        self.publicKey = publicKey
        self.network = network
        self.apiService = apiService
        self.webSocket = webSocket
        self.eventDecoder = eventDecoder
        self.eventEncoder = eventEncoder
    }
    
    // MARK: - Methods
    
    public func setup() async throws {
        try await apiService.initialize(
            parameters: OrbInitializeRequestBody(
                api_key: apiKey,
                public_key: publicKey,
                network: network.value
            )
        )
        
        isInitialized = true
    }
    
    public func connect() async throws {
        guard isInitialized else {
            throw OrbError.notInitialized
        }
        
        webSocket.connect()
    }
    
    public func listen() -> AsyncStream<OrbEvent> {
        AsyncStream { [weak self] continuation in
            self?.webSocket.onEvent = { event in
                guard let orbEvent = self?.eventDecoder.decode(event: event) else {
                    return
                }
                
                continuation.yield(orbEvent)
            }
        }
    }
    
    // MARK: - Send
    
    public func send(message: OrbIntelSendTextMessage) throws {
        webSocket.write(data: try eventEncoder.encode(data: message))
    }
    
    public func send(transactionId: String, txHash: String) throws {
        webSocket.write(
            data: try eventEncoder.encode(
                data: OrbIntelSendTransactionTxHash(id: transactionId, txHash: txHash)
            )
        )
    }
    
    public func send(signedTransaction: OrbIntelSendSignedTransaction) throws {
        webSocket.write(data: try eventEncoder.encode(data: signedTransaction))
    }
    
    public func send(declinedTransactionId: String) throws {
        webSocket.write(
            data: try eventEncoder.encode(
                data: OrbIntelSendDeclinedTransaction(id: declinedTransactionId)
            )
        )
    }
    
    // MARK: - Disconnect
    
    public func disconnect() {
        webSocket.disconnect()
    }
}
