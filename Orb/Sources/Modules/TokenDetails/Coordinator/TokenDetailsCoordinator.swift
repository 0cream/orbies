import ComposableArchitecture
import SwiftNavigation

@Reducer
struct TokenDetailsCoordinator {
    @Dependency(\.userService)
    private var userService: UserService
    
    var body: some Reducer<State, Action> {
        Scope(state: \.root, action: \.root) {
            TokenDetailsFeature()
        }
        
        Reduce { state, action in
            switch action {
            case let .root(.delegate(action)):
                return reduce(state: &state, action: action)
            
            case let .destination(.presented(action)):
                return reduce(state: &state, action: action)
                
            case .root, .destination, .delegate:
                return .none
            }
        }
        .ifLet(\.$destination, action: \.destination)
    }

    // MARK: - Root
    
    private func reduce(state: inout State, action: TokenDetailsFeature.Action.Delegate) -> Effect<Action> {
        switch action {
        case .didFinish:
            return .send(.delegate(.didFinish))
            
        case let .didRequestBuyToken(tokenName, tokenTicker, tokenMintAddress, tokenDecimals, currentPrice, venue):
            state.destination = .tokenBuy(
                TokenBuyCoordinator.State(
                    root: TokenBuyFeature.State(
                        tokenName: tokenName,
                        tokenTicker: tokenTicker,
                        tokenMintAddress: tokenMintAddress,
                        tokenDecimals: tokenDecimals,
                        currentPrice: currentPrice,
                        venue: venue
                    )
                )
            )
            return .none
            
        case let .didRequestSellToken(tokenName, tokenTicker, tokenMintAddress, tokenDecimals, currentPrice, venue, userTokensBalance):
            state.destination = .tokenSell(
                TokenSellCoordinator.State(
                    root: TokenSellFeature.State(
                        tokenName: tokenName,
                        tokenTicker: tokenTicker,
                        tokenMintAddress: tokenMintAddress,
                        tokenDecimals: tokenDecimals,
                        currentPrice: currentPrice,
                        venue: venue,
                        userTokensBalance: userTokensBalance
                    )
                )
            )
            return .none
            
        case let .didRequestNavigateToNewsArticle(article):
            // Delegate to parent (Portfolio) to handle navigation
            return .send(.delegate(.didRequestNavigateToNewsArticle(article: article)))
        }
    }

    // MARK: - Destination
    
    private func reduce(state: inout State, action: Destination.Action) -> Effect<Action> {
        switch action {
        case let .tokenBuy(.delegate(.didFinish(tokenAmount, tokenTicker))):
            state.destination = nil
            // Force refresh balances and show activity popup
            let formattedAmount = formatAmount(tokenAmount)
            return .merge(
                .run { [userService] _ in
                    await userService.forceRefreshBalances()
                },
                .send(.root(.reducer(.showActivityPopup(text: "Bought \(formattedAmount) \(tokenTicker)", emoji: "💸", isSuccess: true))))
            )
            
        case let .tokenBuy(.delegate(.didRequestPurchase(tokenName, tokensAmount, tokensAmountWithFee, usdcAmount, usdAmount, fee))):
            // TODO: Handle purchase confirmation and execution
            print("🛒 Purchase requested: \(tokenName)")
            print("   Tokens: \(Double(tokensAmountWithFee.value) / Double(Token.fractional.precision))")
            print("   USDC: $\(usdcAmount.USDC)")
            print("   Fee: $\(fee.USDC)")
            state.destination = nil
            return .none
            
        case let .tokenBuy(.delegate(.didRequestTopUp(amount))):
            // Show WalletReceive for top-up
            if let amount = amount {
                print("💰 Top-up requested: $\(amount.USDC)")
            } else {
                print("💰 Top-up requested")
            }
            state.destination = .walletReceive(WalletReceiveCoordinator.State())
            return .none
            
        case .tokenBuy(.delegate(.didFail(_))):
            state.destination = nil
            return .send(.root(.reducer(.showActivityPopup(text: "Swap failed", emoji: "🔴", isSuccess: false))))
            
        case .tokenBuy:
            return .none
            
        case let .tokenSell(.delegate(.didFinish(usdcAmount, tokenTicker))):
            state.destination = nil
            // Force refresh balances and show activity popup
            let formattedAmount = formatAmount(usdcAmount)
            return .merge(
                .run { [userService] _ in
                    await userService.forceRefreshBalances()
                },
                .send(.root(.reducer(.showActivityPopup(text: "Sold \(formattedAmount) \(tokenTicker)", emoji: "💸", isSuccess: true))))
            )
            
        case let .tokenSell(.delegate(.didRequestSell(tokenName, tokensAmount, usdcAmount, usdAmount, fee))):
            // TODO: Handle sell confirmation and execution
            print("💰 Sell requested: \(tokenName)")
            print("   Tokens: \(Double(tokensAmount.value) / Double(Token.fractional.precision))")
            print("   USDC: $\(usdcAmount.USDC)")
            print("   Fee: $\(fee.USDC)")
            state.destination = nil
            return .none
            
        case .tokenSell(.delegate(.didFail(_))):
            state.destination = nil
            return .send(.root(.reducer(.showActivityPopup(text: "Swap failed", emoji: "🔴", isSuccess: false))))
            
        case .tokenSell:
            return .none
            
        case .walletReceive(.delegate(.didClose)):
            state.destination = nil
            return .none
            
        case .walletReceive:
            return .none
        }
    }
    
    // MARK: - Helpers
    
    private func formatAmount(_ amount: Double) -> String {
        if amount >= 1_000_000 {
            return String(format: "%.1fM", amount / 1_000_000)
        } else if amount >= 1_000 {
            return String(format: "%.1fK", amount / 1_000)
        } else if amount >= 1 {
            return String(format: "%.1f", amount)
        } else {
            return String(format: "%.2f", amount)
        }
    }
} 
