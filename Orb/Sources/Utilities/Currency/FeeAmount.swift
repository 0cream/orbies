import Foundation

/// Fee structure for trading transactions (buy/sell)
struct FeeAmount: Equatable, Codable {
    let estimatedFee: Double // Fee in USDC
    let accountRentExemption: Double // Rent exemption in USDC
    
    var total: Double {
        estimatedFee + accountRentExemption
    }
    
    static let mock = FeeAmount(
        estimatedFee: 0.01, // Mock $0.01 fee
        accountRentExemption: 0.0 // No rent exemption for USDC
    )
}

