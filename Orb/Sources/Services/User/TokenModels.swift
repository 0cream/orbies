import SwiftUI

// MARK: - Token Grade

enum TokenGrade: String, Equatable, CaseIterable {
    case common
    case uncommon
    case rare
    case mythical
    case legendary
    case ancient
    case exceedinglyRare = "exceedingly_rare"
    case immortal
    
    var color: Color {
        switch self {
        case .common: return Color(rgb: 0xF1F1F1)
        case .uncommon: return Color(rgb: 0x7092EA)
        case .rare: return Color(rgb: 0x305AFD)
        case .mythical: return Color(rgb: 0xA242F4)
        case .legendary: return Color(rgb: 0xFF1EE8)
        case .ancient: return Color(rgb: 0xFF1EE8)
        case .exceedinglyRare: return Color(rgb: 0xFFE819)
        case .immortal: return Color(rgb: 0xFF832F)
        }
    }
}

// MARK: - Token Metadata

struct TokenMetadata: Equatable {
    let id: String
    let name: String
    let ticker: String
    let imageName: String
    let grade: TokenGrade
    let initialPrice: Double
}

