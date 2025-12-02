import Foundation
import Dependencies
import OrbIntel
// MARK: - Protocol

protocol OrbIntelligenceService: Sendable {
    func setup() async throws
    func observe() -> AsyncStream<[OrbMessage]>
    func send(message: String)
    func send(message: String) async throws
}

// MARK: - Live Implementation

final class LiveOrbIntelligenceService: OrbIntelligenceService {

    // MARK: - Private Properties
    
    private nonisolated(unsafe) let orbIntel: OrbIntel
    
    // MARK: - Init
    
    init() {
        orbIntel = try! OrbIntelBuilder.shared.build(
            url: URL(string: "https://app.whsprs.ai/api-dev/")!,
            webSocketUrl: URL(string: "wss://app.whsprs.ai/api-dev/ws")!,
            apiKey: "ILoveSergeyShalnov",
            publicKey: "0x0",
            network: .devnet
        )
    }
    
    // MARK: - Methods
    
    func setup() async throws {
        try await orbIntel.setup()
        try await orbIntel.connect()
        Task { @MainActor [weak self] in
            await self?._listen()
        }
    }
    
    private nonisolated(unsafe) var continuation: AsyncStream<[OrbMessage]>.Continuation?
    private nonisolated(unsafe) var allMessages: [OrbMessage] = []
    
    func observe() -> AsyncStream<[OrbMessage]> {
        AsyncStream { [weak self] continuation in
            self?.continuation = continuation
            
            continuation.onTermination = { [weak self] _ in
                self?.continuation = nil
            }
        }
    }
    
    private func _listen() async {
        for await event in orbIntel.listen() {
            let message = mapEvent(event)
            allMessages.append(message)
            continuation?.yield(allMessages)
        }
    }
    
    private func mapEvent(_ event: OrbEvent) -> OrbMessage {
        switch event {
        case .textMessage(let textMessage):
            return OrbMessage(
                id: textMessage.id,
                content: .text(
                    OrbMessageContent.Text(
                        id: textMessage.id,
                        text: textMessage.text,
                        author: .orb
                    )
                ),
                status: OrbMessageStatus(rawValue: textMessage.status.rawValue) ?? .processing
            )
            
        case .status(let status):
            return OrbMessage(
                id: status.id,
                content: .status(
                    OrbMessageContent.Status(
                        id: status.id,
                        text: status.text
                    )
                ),
                status: .processing
            )
            
        case .transactionRequest:
            // Transaction request - we can't access internal properties
            return OrbMessage(
                id: UUID().uuidString,
                content: .transactionRequest(
                    OrbMessageContent.TransactionRequest(
                        id: "tx-\(UUID().uuidString)",
                        transaction: ""
                    )
                ),
                status: .processing
            )
            
        case .disconnected(let reason):
            return OrbMessage(
                id: UUID().uuidString,
                content: .disconnected(reason),
                status: .failed
            )
            
        case .unknown:
            return OrbMessage(
                id: UUID().uuidString,
                content: .unknown,
                status: .failed
            )
        }
    }
    
    private func sendToOrb(message: String) {
        try? orbIntel.send(message: OrbIntelSendTextMessage(text: message))
        
        let userMessage = OrbMessage(
            id: UUID().uuidString,
            content: .text(
                OrbMessageContent.Text(
                    id: UUID().uuidString,
                    text: message,
                    author: .user
                )
            ),
            status: .completed
        )
        allMessages.append(userMessage)
        continuation?.yield(allMessages)
    }
    
    func send(message: String) {
        sendToOrb(message: message)
    }
    
    func send(message: String) async throws {
        sendToOrb(message: message)
    }
}

// MARK: - Mock Implementation

struct MockOrbIntelligenceService: OrbIntelligenceService {
    func setup() async throws {
        // Mock implementation
    }
    
    func observe() -> AsyncStream<[OrbMessage]> {
        AsyncStream { _ in }
    }
    
    func send(message: String) {
        // Mock implementation
    }
    
    func send(message: String) async throws {
        // Mock implementation
    }
}

// MARK: - Dependency

private enum OrbIntelligenceServiceKey: DependencyKey {
    static let liveValue: any OrbIntelligenceService = LiveOrbIntelligenceService()
    static let testValue: any OrbIntelligenceService = MockOrbIntelligenceService()
}

extension DependencyValues {
    var orbIntelligenceService: any OrbIntelligenceService {
        get { self[OrbIntelligenceServiceKey.self] }
        set { self[OrbIntelligenceServiceKey.self] = newValue }
    }
}

