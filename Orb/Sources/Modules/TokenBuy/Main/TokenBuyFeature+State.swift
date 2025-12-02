import Foundation
import ComposableArchitecture

extension TokenBuyFeature {
    @ObservableState
    struct State: Equatable {
        enum ActionButtonState: String {
            case enterAmount = "enter_amount"
            case topUpAndBuy = "top_up_and_buy"
            case buy
        }
        
        enum ToolbarSecondaryButtonState: String {
            case topUp = "top_up"
            case useMax = "use_max"
        }
        
        // MARK: - Immutable Properties
        
        let tokenName: String
        let tokenTicker: String
        let tokenMintAddress: String
        let tokenDecimals: Int
        let currentPrice: Double // Price per token in USDC
        let venue: TradingVenue
        
        // MARK: - Mutable State
        
        var inputShakeIdentifier = UUID()
        var balance: Usdc = .zero
        var feeAmount: FeeAmount?
        var buyUsdcAmount: Usdc = .zero
        var buyUsdAmount: Usd = .zero
        var input: String = "$0"
        var tokenReserves: TokenReserves?
        
        // Jupiter Ultra swap quote state
        var swapQuote: JupiterUltraOrder?
        var isLoadingQuote: Bool = false
        var quoteError: String?
        var lastQuoteUpdateTime: Date?
        
        // Transaction execution
        var isExecutingSwap: Bool = false
        var executingTransactionSignature: String?
        
        // MARK: - Computed Properties
        
        var accountRentExemption: Usdc {
            // TODO: Get actual rent exemption from Solana
            // For now, approximate ~0.002 SOL = ~$0.40 in USDC
            Usdc(usdc: 0.40)
        }
        
        var fee: Usdc {
            guard let feeAmount else { return .zero }
            // TODO: Calculate actual fees based on FeeAmount
            // For now, simplified
            return Usdc(usdc: feeAmount.estimatedFee)
        }
        
        var availableBalance: Usdc {
            let value = balance.value
                - fee.value
                - accountRentExemption.value
            
            return Usdc(value: max(0, value))
        }
        
        var isEnoughBalance: Bool {
            buyUsdcAmount <= availableBalance
        }
        
        var isInputAmountAboveZero: Bool {
            buyUsdAmount > .zero
        }
        
        // NOTE: These are computed in TokenBuyFeature using the injected service
        var buyTokensAmount: Token = .zero
        var buyTokensAmountWithFee: Token = .zero
        
        var actionButtonState: ActionButtonState {
            if isInputAmountAboveZero == false {
                return .enterAmount
            } else if isEnoughBalance == false {
                return .topUpAndBuy
            } else {
                return .buy
            }
        }
        
        var toolbarSecondaryButtonState: ToolbarSecondaryButtonState {
            if balance == .zero || isEnoughBalance == false {
                return .topUp
            } else {
                return .useMax
            }
        }
        
        var displayTokenName: String {
            tokenTicker
        }
        
        // MARK: - Init
        
        init(
            tokenName: String,
            tokenTicker: String,
            tokenMintAddress: String,
            tokenDecimals: Int = 6,
            currentPrice: Double,
            venue: TradingVenue
        ) {
            self.tokenName = tokenName
            self.tokenTicker = tokenTicker
            self.tokenMintAddress = tokenMintAddress
            self.tokenDecimals = tokenDecimals
            self.currentPrice = currentPrice
            self.venue = venue
            
            // Initialize with mock reserves based on current price
            // TODO: Fetch actual reserves from backend
            let mockTokenReserve: UInt64 = 1_000_000 * 1_000_000 // 1M tokens
            let mockUsdcReserve = Int64(Double(mockTokenReserve) * currentPrice)
            
            self.tokenReserves = TokenReserves(
                virtualTokenReserves: Token(value: mockTokenReserve),
                virtualUsdcReserves: Usdc(value: mockUsdcReserve),
                venue: venue
            )
        }
    }
}

