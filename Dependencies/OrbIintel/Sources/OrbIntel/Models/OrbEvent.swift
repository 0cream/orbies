public enum OrbEvent: Sendable {
    case textMessage(OrbTextMessage)
    case status(OrbStatus)
    case transactionRequest(OrbTransactionRequest)
    case disconnected(reason: String)
    case unknown
}

// MARK: - Parsing

extension OrbEvent: Decodable {
    enum EventType: String, Decodable {
        case text_message
        case status
        case transaction_request
        case unknown
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let type = try container.decode(EventType.self, forKey: .type)
        
        switch type {
        case .status:
            let data = try container.decode(OrbStatus.self, forKey: .data)
            self = .status(data)
        case .text_message:
            let data = try container.decode(OrbTextMessage.self, forKey: .data)
            self = .textMessage(data)
            
        case .transaction_request:
            let data = try container.decode(OrbTransactionRequest.self, forKey: .data)
            self = .transactionRequest(data)
            
        case .unknown:
            self = .unknown
        }
    }
    
    enum CodingKeys: String, CodingKey {
        case type
        case data
    }
}

// MARK: - Text Message

public enum OrbTextMessageStatus: String, Sendable, Decodable {
    case processing
    case completed
    case failed
}

public struct OrbTextMessage: Sendable, Decodable {
    public let id: String
    public let text: String
    public let status: OrbTextMessageStatus
}

// MARK: - Status

public struct OrbStatus: Sendable, Decodable {
    public let id: String
    public let text: String
}

// MARK: - Transaction Request

public struct OrbTransactionRequest: Sendable, Decodable {
    let id: String
    let transaction: String
}

