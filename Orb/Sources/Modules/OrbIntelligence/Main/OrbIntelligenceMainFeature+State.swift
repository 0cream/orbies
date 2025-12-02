import ComposableArchitecture
import Foundation
import SwiftUI

struct OrbIntelligenceMessage: Identifiable, Equatable {
    enum Direction: Equatable {
        case income
        case outgoing
    }
    
    enum Content: Equatable {
        case text(String)
        case error(String)
        case loading(String)
    }
    
    let id: String
    let direction: Direction
    var content: Content
    
    var text: String? {
        guard case let .text(value) = content else {
            return nil
        }
        
        return value
    }
}

extension Array {
    var nonEmpty: Self? {
        isEmpty ? nil : self
    }
}

extension OrbIntelligenceMainFeature {
    @ObservableState
    struct State {
        var preInput: String?
        
        var suggests: [String] = []
        var input = ""

        var focusedField: Field?
        
        var events: [OrbMessage] = []
        
        var messages: [OrbIntelligenceMessage] {
            events.compactMap { event in
                switch event.content {
                case let .text(message):
                    return OrbIntelligenceMessage(
                        id: event.id,
                        direction: message.author == .user ? .outgoing : .income,
                        content: .text(message.text)
                    )

                case let .status(status):
                    return OrbIntelligenceMessage(
                        id: event.id,
                        direction: .income,
                        content: .loading(status.text)
                    )
                    
                case .transactionRequest:
                    // Handle transaction requests if needed
                    return nil
                    
                case let .disconnected(reason):
                    return OrbIntelligenceMessage(
                        id: event.id,
                        direction: .income,
                        content: .error(reason)
                    )
                    
                case .unknown:
                    return nil
                }
            }
        }
        
        var isInputEnabled = true

        var scrollTo: String?
        
        enum Field {
            case input
        }
    }
}

