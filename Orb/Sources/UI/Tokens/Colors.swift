import SwiftUI

extension Color {
    static var tokens: Tokens.Colors.Type {
        Tokens.Colors.self
    }
    
    static var inventory: Tokens.Colors.Type {
        Tokens.Colors.self
    }
}

extension ShapeStyle where Self == Color {
    static var tokens: Tokens.Colors.Type {
        Tokens.Colors.self
    }
    
    static var inventory: Tokens.Colors.Type {
        Tokens.Colors.self
    }
}

struct Tokens {
    struct Colors {
        // Black shades
        static let black004 = Color(rgb: 0x000000).opacity(0.04)
        static let black008 = Color(rgb: 0x000000).opacity(0.08)
        static let black100 = Color(rgb: 0x000000)
        static let systemBlack = Color(rgb: 0x000000)
        
        // White shades
        static let white040 = Color(rgb: 0xFFFFFF).opacity(0.4)
        static let white095 = Color(rgb: 0xFFFFFF).opacity(0.95)
        static let white100 = Color(rgb: 0xFFFFFF)
        static let systemWhite = Color(rgb: 0xFFFFFF)
        
        // Text colors
        static let textPrimary = Color(rgb: 0x111111)
        static let textSecondary = Color(rgb: 0x8A8D92)
        static let textTertiary = Color(rgb: 0x9FA5AC)
        static let textDisabled = Color(rgb: 0xC7C7CC)
        static let textPrimaryInverted = Color(rgb: 0xFFFFFF)
        static let textSecondaryAlt = Color(rgb: 0x727A84)
        static let textThird = Color(rgb: 0x000000).opacity(0.15)
        static let invertedTextPrimary = Color(rgb: 0xF5F5F5)
        static let invertedTextSecondary = Color(rgb: 0x606060)
        
        // Brand colors
        static let green = Color(rgb: 0x23CE6B)
        static let greenBackground = Color(rgb: 0x23CE6B).opacity(0.1)
        static let systemGreen = Color(rgb: 0x50CE87)
        static let privacyBlue = Color(rgb: 0x008CFF)
        static let red = Color(red: 1.0, green: 0.3, blue: 0.3)
        static let systemRed = Color(rgb: 0xF9564F)
        
        // System colors
        static let systemBlue = Color.blue
        static let lightBlue = Color(rgb: 0x1DA1F3)
        static let keyBlue = Color(rgb: 0x0075FB)
        static let systemOrange = Color(rgb: 0xF96E46)
        static let systemPeach = Color(rgb: 0xFFA869)
        static let systemPurple = Color(rgb: 0x773CF4)
        static let systemTeal = Color(rgb: 0x5AC8FA)
        static let systemYellow = Color(rgb: 0xFFBC42)
        
        // Background colors
        static let levelRoot = Color(rgb: 0xF5F5F5)
        static let lightGrey = Color(rgb: 0xF2F3F4)
        static let invertedLevelSurface = Color(rgb: 0x1C1C1C)
        static let invertedLevelElevation = Color.white.opacity(0.04)
        static let fillTertiary = Color(rgb: 0x787880).opacity(0.12)
        
        // External services
        static let solana = Color(rgb: 0x9945FF)
    }
}
