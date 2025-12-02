import Foundation
import ComposableArchitecture

extension TokenSellFeature {
    @ObservableState
    struct State {
        enum ActionButtonState: String {
            case enterAmount
            case youHaveNothingToSell
            case insufficientBalance
            case sell
            case incorrectAmount
        }
        
        struct ToolbarSecondaryAction: Equatable {
            enum ToolbarSecondaryActionType: String {
                case percent25
                case percent50
                case percent75
                case max
            }
            
            let type: ToolbarSecondaryActionType
            let multiplier: Double
            
            static let percent25 = Self(type: .percent25, multiplier: 0.25)
            static let percent50 = Self(type: .percent50, multiplier: 0.5)
            static let percent75 = Self(type: .percent75, multiplier: 0.75)
            static let max = Self(type: .max, multiplier: 1)
        }
        
        // MARK: - Immutable Properties
        
        let tokenName: String
        let tokenTicker: String
        let tokenMintAddress: String
        let tokenDecimals: Int
        let currentPrice: Double // Price per token in USDC
        let venue: TradingVenue
        
        let toolbarSecondaryActions: [ToolbarSecondaryAction] = [
            .percent25,
            .percent50,
            .percent75,
            .max
        ]
        
        // MARK: - Mutable State
        
        var inputShakeIdentifier = UUID()
        var balanceShakeIdentifier = UUID()
        var balance: Usdc = .zero
        var feeAmount: FeeAmount?
        var tokensBalance: Token = .zero
        var sellTokensAmount = Token.zero
        var input: String = "0"
        var tokenReserves: TokenReserves?
        
        // Calculated values (updated by reducer)
        var tokensBalanceInUsdc: Usdc = .zero
        var sellTokensAmountInUsdc: Usdc = .zero
        
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
            // TODO: Get actual rent exemption
            Usdc(usdc: 0.40)
        }
        
        var fee: Usdc {
            guard let feeAmount else { return .zero }
            return Usdc(usdc: feeAmount.estimatedFee)
        }
        
        var isEnoughBalance: Bool {
            sellTokensAmount.value <= tokensBalance.value
        }
        
        var isInputAmountAboveZero: Bool {
            sellTokensAmount.value > .zero
        }
        
        var sellTokensAmountInUsdcWithFee: Usdc {
            Usdc(value: max(0, sellTokensAmountInUsdc.value - fee.value))
        }
        
        var actionButtonState: ActionButtonState {
            guard tokensBalance.value > .zero else {
                return .youHaveNothingToSell
            }
            
            guard sellTokensAmount.units < NSDecimalNumber(value: 1_000_000_000) else {
                return .incorrectAmount
            }
            
            guard isEnoughBalance else {
                return .insufficientBalance
            }
            
            guard isInputAmountAboveZero else {
                return .enterAmount
            }
            
            return .sell
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
            venue: TradingVenue,
            userTokensBalance: Double
        ) {
            self.tokenName = tokenName
            self.tokenTicker = tokenTicker
            self.tokenMintAddress = tokenMintAddress
            self.tokenDecimals = tokenDecimals
            self.currentPrice = currentPrice
            self.venue = venue
            self.tokensBalance = Token(units: userTokensBalance)
            
            // Initialize with mock reserves
            let mockTokenReserve: UInt64 = 1_000_000 * 1_000_000
            let mockUsdcReserve = Int64(Double(mockTokenReserve) * currentPrice)
            
            self.tokenReserves = TokenReserves(
                virtualTokenReserves: Token(value: mockTokenReserve),
                virtualUsdcReserves: Usdc(value: mockUsdcReserve),
                venue: venue
            )
        }
    }
}

