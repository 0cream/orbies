import OrbIntel

// MARK: - OrbMessage Model

struct OrbMessage: Sendable {
    let id: String
    let content: OrbMessageContent
    let status: OrbMessageStatus
}

enum OrbMessageStatus: String, Equatable, Sendable {
    case processing
    case completed
    case failed
}

enum OrbMessageContent: Sendable {
    case status(Status)
    case text(Text)
    case transactionRequest(TransactionRequest)
    case disconnected(String)
    case unknown
}

extension OrbMessageContent {
    struct Status: Sendable {
        let id: String
        let text: String
    }
    
    struct Text: Sendable {
        enum Author: String, Sendable {
            case orb
            case user
        }
        
        let id: String
        let text: String
        let author: Author
    }
    
    struct TransactionRequest: Sendable {
        let id: String
        let transaction: String
    }
}
