import Foundation
import Dependencies

/// Trading venue where tokens are traded
enum TradingVenue: Equatable, Codable {
    case meteoraDBC  // Meteora Dynamic Bonding Curve
    case meteoraDAMMV2  // Meteora DAMM V2 (after bonding)
}

/// Reserves data for bonding curve calculations
struct TokenReserves: Equatable, Codable {
    let virtualTokenReserves: Token
    let virtualUsdcReserves: Usdc
    let venue: TradingVenue
}

// MARK: - Protocol

protocol TradingCalculationService: Sendable {
    /// Calculate tokens to receive for a given USDC amount
    func buyAmount(amount: Usdc, tokenReserves: TokenReserves) -> Token
    
    /// Calculate USDC to receive for a given token amount
    func sellAmount(amount: Token, tokenReserves: TokenReserves) -> Usdc
    
    /// Calculate buy amount on Meteora DAMM V2
    func meteoraDAMMV2BuyAmount(amount: Usdc, tokenReserve: UInt64, usdcReserve: UInt64, slippage: Double) -> Token
    
    /// Calculate sell amount on Meteora DAMM V2
    func meteoraDAMMV2SellAmount(amount: Token, tokenReserve: UInt64, usdcReserve: UInt64, slippage: Double) -> Usdc
}

// MARK: - Live Implementation

struct LiveTradingCalculationService: TradingCalculationService {
    
    // MARK: - Buy Amount Calculations
    
    func buyAmount(
        amount: Usdc,
        tokenReserves: TokenReserves
    ) -> Token {
        // TODO: Implement proper Meteora DBC/DAMMV2 calculations
        // For now, simplified: just divide USDC by current price
        // This will be replaced with actual bonding curve math
        return buyAmountSimplified(amount: amount, tokenReserves: tokenReserves)
    }
    
    /// TEMPORARY: Simplified calculation using direct price division
    /// This is a placeholder until we implement proper Meteora bonding curve math
    private func buyAmountSimplified(
        amount: Usdc,
        tokenReserves: TokenReserves
    ) -> Token {
        // Calculate current price: USDC reserve / Token reserve
        let currentPrice = NSDecimalNumber(value: tokenReserves.virtualUsdcReserves.value)
            .dividing(by: NSDecimalNumber(value: tokenReserves.virtualTokenReserves.value))
        
        // Tokens to receive = USDC amount / price
        let tokensAmount = NSDecimalNumber(value: amount.value)
            .dividing(by: currentPrice)
            .rounding(accordingToBehavior: NSDecimalNumberHandler.roundDown)
        
        return Token(
            value: UInt64(truncating: tokensAmount)
        )
    }
    
    /// Full bonding curve calculation (commented out for now)
    /*
    private func buyAmountBondingCurve(
        amount: Usdc,
        virtualTokenReserves: Token,
        virtualUsdcReserves: Usdc,
        slippage: Double
    ) -> Token {
        /// Meteora DBC Formula:
        /// tokens_to_receive = (token_reserve * usdc_amount) / (usdc_reserve + usdc_amount)
        let tokensAmountNumber = NSDecimalNumber(value: virtualTokenReserves.value)
            .multiplying(by: NSDecimalNumber(value: amount.value))
            .dividing(
                by: NSDecimalNumber(value: virtualUsdcReserves.value)
                    .adding(NSDecimalNumber(value: amount.value))
            )
            .multiplying(by: NSDecimalNumber(value: 1 - slippage))
            .rounding(accordingToBehavior: NSDecimalNumberHandler.roundDown)
        
        return Token(
            value: UInt64(truncating: tokensAmountNumber)
        )
    }
    */
    
    // MARK: - Sell Amount Calculations
    
    func sellAmount(
        amount: Token,
        tokenReserves: TokenReserves
    ) -> Usdc {
        // TODO: Implement proper Meteora DBC/DAMMV2 calculations
        // For now, simplified: just multiply tokens by current price
        return sellAmountSimplified(amount: amount, tokenReserves: tokenReserves)
    }
    
    /// TEMPORARY: Simplified calculation using direct price multiplication
    private func sellAmountSimplified(
        amount: Token,
        tokenReserves: TokenReserves
    ) -> Usdc {
        // Calculate current price: USDC reserve / Token reserve
        let currentPrice = NSDecimalNumber(value: tokenReserves.virtualUsdcReserves.value)
            .dividing(by: NSDecimalNumber(value: tokenReserves.virtualTokenReserves.value))
        
        // USDC to receive = tokens * price
        let usdcAmount = NSDecimalNumber(value: amount.value)
            .multiplying(by: currentPrice)
            .rounding(accordingToBehavior: NSDecimalNumberHandler.roundDown)
        
        return Usdc(
            value: Int64(truncating: usdcAmount)
        )
    }
    
    /// Full bonding curve calculation (commented out for now)
    /*
    private func sellAmountBondingCurve(
        amount: Token,
        virtualTokenReserves: Token,
        virtualUsdcReserves: Usdc,
        slippage: Double
    ) -> Usdc {
        /// Meteora DBC Formula:
        /// usdc_to_receive = (tokens_sold * usdc_reserve) / (token_reserve + tokens_sold)
        let usdcAmountNumber = NSDecimalNumber(value: virtualUsdcReserves.value)
            .multiplying(by: NSDecimalNumber(value: amount.value))
            .dividing(
                by: NSDecimalNumber(value: virtualTokenReserves.value)
                    .adding(NSDecimalNumber(value: amount.value))
            )
            .multiplying(by: NSDecimalNumber(value: 1 - slippage))
            .rounding(accordingToBehavior: NSDecimalNumberHandler.roundDown)
        
        return Usdc(
            value: Int64(truncating: usdcAmountNumber)
        )
    }
    */
    
    // MARK: - Meteora DAMM V2 Calculations
    
    func meteoraDAMMV2BuyAmount(
        amount: Usdc,
        tokenReserve: UInt64,
        usdcReserve: UInt64,
        slippage: Double
    ) -> Token {
        // TODO: Implement Meteora DAMM V2 specific math
        // For now, use same simplified calculation
        return buyAmountSimplified(
            amount: amount,
            tokenReserves: TokenReserves(
                virtualTokenReserves: Token(value: tokenReserve),
                virtualUsdcReserves: Usdc(value: Int64(usdcReserve)),
                venue: .meteoraDAMMV2
            )
        )
    }
    
    func meteoraDAMMV2SellAmount(
        amount: Token,
        tokenReserve: UInt64,
        usdcReserve: UInt64,
        slippage: Double
    ) -> Usdc {
        // TODO: Implement Meteora DAMM V2 specific math
        // For now, use same simplified calculation
        return sellAmountSimplified(
            amount: amount,
            tokenReserves: TokenReserves(
                virtualTokenReserves: Token(value: tokenReserve),
                virtualUsdcReserves: Usdc(value: Int64(usdcReserve)),
                venue: .meteoraDAMMV2
            )
        )
    }
}

// MARK: - Dependency

extension DependencyValues {
    var tradingCalculationService: TradingCalculationService {
        get { self[TradingCalculationServiceKey.self] }
        set { self[TradingCalculationServiceKey.self] = newValue }
    }
}

private enum TradingCalculationServiceKey: DependencyKey {
    static let liveValue: TradingCalculationService = LiveTradingCalculationService()
    static let testValue: TradingCalculationService = { preconditionFailure() }()
}
