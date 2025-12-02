public enum OrbIntelSendEvent: String, Codable {
    case text_message
    case tx_hash
    case signed_transaction
    case decline_transaction
}

// MARK: - Text Message

public struct OrbIntelSendTextMessage: Encodable {
    public struct Data: Encodable {
        /// User text message to orb
        public let text: String
    }
    
    /// Describes send event type
    public let type = OrbIntelSendEvent.text_message
    /// Describes send event data
    public let data: Data
    
    /// Returns user text message event
    /// - Parameter text: User text message to orb
    public init(text: String) {
        self.data = Data(text: text)
    }
}

// MARK: - Transaction

public struct OrbIntelSendDeclinedTransaction: Encodable {
    public struct Data: Encodable {
        /// Orb transaction identifier
        public let id: String
    }
    
    /// Describes send event type
    public let type = OrbIntelSendEvent.decline_transaction
    /// Describes send event data
    public let data: Data
    
    /// Returns declined transaction event
    /// - Parameter id: Orb transaction identifier
    init(id: String) {
        self.data = Data(id: id)
    }
}

public struct OrbIntelSendTransactionTxHash: Encodable {
    public struct Data: Encodable {
        /// Orb transaction identifier
        public let id: String
        public let tx_hash: String
    }
    
    /// Describes send event type
    public let type = OrbIntelSendEvent.tx_hash
    /// Describes send event data
    public let data: Data
    
    /// Returns declined transaction event
    /// - Parameter id: Orb transaction identifier
    init(id: String, txHash: String) {
        self.data = Data(id: id, tx_hash: txHash)
    }
}

public struct OrbIntelSendSignedTransaction: Encodable {
    public struct Data: Encodable {
        /// Orb transaction identifier
        public let id: String
        /// Signed transaction (base64)
        public let signed_transaction: String
    }
    
    /// Describes send event type
    public let type = OrbIntelSendEvent.signed_transaction
    /// Describes send event data
    public let data: Data
    
    /// Returns event with signed transaction from orb
    /// - Parameters:
    ///   - id: Orb transaction identifier
    ///   - signed_transaction: Signed transaction (base64)
    public init(
        id: String,
        signedTransaction: String
    ) {
        self.data = Data(id: id, signed_transaction: signedTransaction)
    }
}
