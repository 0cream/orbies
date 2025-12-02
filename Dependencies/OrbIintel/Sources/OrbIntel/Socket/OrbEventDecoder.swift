import Foundation
import Starscream

protocol OrbEventDecoder {
    func decode(event: WebSocketEvent) -> OrbEvent?
}

final class LiveOrbEventDecoder: OrbEventDecoder {
    
    // MARK: - Private Properties
    
    private let decoder: JSONDecoder
    private let isLoggingEnabled: Bool
    
    // MARK: - Init
    
    init(
        decoder: JSONDecoder,
        isLoggingEnabled: Bool
    ) {
        self.decoder = decoder
        self.isLoggingEnabled = isLoggingEnabled
    }
    
    // MARK: - Methods
    
    func decode(event: WebSocketEvent) -> OrbEvent? {
        switch event {
        case .connected:
            break
            
        case let .disconnected(reason, _):
            return .disconnected(reason: reason)
            
        case .text:
            break
            
        case let .binary(data):
            guard let event = try? decoder.decode(OrbEvent.self, from: data) else {
                return nil
            }
            
            return event
            
        case .pong:
            log("[Orb] Socket: - Pong")
            
        case .ping:
            log("[Orb] Socket: - Ping")
            
        case let .error(error):
            log("[Orb] Socket: - \(error?.localizedDescription ?? "error occured")")
            
        case .viabilityChanged(let bool):
            log("[Orb] Socket: - Viability changed: \(bool)")
            
        case .reconnectSuggested(let bool):
            log("[Orb] Socket: - Reconnect suggested: \(bool)")
            
        case .cancelled:
            log("[Orb] Socket: - Cancelled")
            
        case .peerClosed:
            log("[Orb] Socket: - Peer closed")
        }
        
        return nil
    }
    
    // MARK: - Private
    
    private func log(_ message: String) {
        if isLoggingEnabled {
            print("[Orb] Socket: - Peer closed")
        }
    }
}
