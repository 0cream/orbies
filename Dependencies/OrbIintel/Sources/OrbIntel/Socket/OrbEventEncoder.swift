import Foundation

protocol OrbEventEncoder {
    func encode(data: Encodable) throws -> Data
}

final class LiveOrbEventEncoder: OrbEventEncoder {
    
    // MARK: - Private Properties
    
    private let encoder: JSONEncoder
    
    // MARK: - Init
    
    init(encoder: JSONEncoder) {
        self.encoder = encoder
    }
    
    // MARK: - OrbEventEncoder
    
    func encode(data: Encodable) throws -> Data {
        try encoder.encode(data)
    }
}
