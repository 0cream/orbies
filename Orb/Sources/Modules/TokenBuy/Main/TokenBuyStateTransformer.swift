import Foundation

/// Transforms TokenBuyFeature.State into TokenNumpadViewState
struct TokenBuyStateTransformer: TokenNumpadStateToViewStateTransformerProtocol {
    
    // MARK: - Methods
    
    func transform(_ state: TokenBuyFeature.State) -> TokenNumpadViewState {
        let inputFooter = makeInputFooter(state: state)
        let toolbarSecondaryButtonTitle = makeToolbarSecondaryButtonTitle(state: state)
        let actionButtonTitle = makeActionButtonTitle(state: state)
        let toolbar = TokenNumpadToolbarViewState(
            title: "Your USDC balance",
            subtitle: "\(makeBalanceDisplayValue(state: state))",
            subtitleShakeId: nil,
            secondaryButton: state.availableBalance > .zero
                ? toolbarSecondaryButtonTitle
                : "Top up",
            secondaryItems: nil,
            style: state.isEnoughBalance
                ? .idle
                : .negative,
            isVisible: state.feeAmount != nil
        )
        
        return TokenNumpadViewState(
            title: "Buy \(state.displayTokenName)",
            input: state.input,
            inputDecimalsLimit: 2,
            inputShakeIdentifier: state.inputShakeIdentifier,
            inputDoubleValue: Double(state.input.digitsWithDots) ?? .zero,
            inputStringValue: state.input,
            inputFooter: inputFooter,
            toolbar: toolbar,
            actionButton: TokenNumpadActionButtonState(
                id: state.actionButtonState.rawValue,
                title: actionButtonTitle,
                titleDouble: state.swapQuote?.inUsdValue ?? state.buyUsdcAmount.USDC,
                isEnabled: state.isInputAmountAboveZero && state.feeAmount != nil && !state.isExecutingSwap,
                isLoading: state.feeAmount == nil || state.isExecutingSwap
            )
        )
    }
    
    // MARK: - Helpers
    
    private func makeBalanceDisplayValue(state: TokenBuyFeature.State) -> String {
        let balanceString = String(format: "%.2f", state.balance.USDC)
        var displayText = "$\(balanceString) USDC"
        
        // Add quote info if available
        if let quote = state.swapQuote {
            let routerName = quote.router.capitalized
            displayText += " • via \(routerName)"
        }
        
        return displayText
    }
    
    private func makeActionButtonTitle(state: TokenBuyFeature.State) -> String {
        switch state.actionButtonState {
        case .enterAmount:
            return "Enter the amount"
            
        case .topUpAndBuy:
            return "Top up and buy for \(makeActionButtonTitleValue(state: state))"
            
        case .buy:
            return "Buy for \(makeActionButtonTitleValue(state: state))"
        }
    }
    
    private func makeActionButtonTitleValue(state: TokenBuyFeature.State) -> String {
        // Use quote data if available for more accurate pricing
        let usdcAmount: Double
        if let quote = state.swapQuote, let inUsdValue = quote.inUsdValue {
            usdcAmount = inUsdValue
        } else {
            usdcAmount = state.buyUsdcAmount.USDC
        }
        
        let minimumVisibleAmount = 0.01
        let enteredDisplayValue = String(format: "%.2f", usdcAmount)
        
        if usdcAmount < minimumVisibleAmount {
            return "<$\(String(format: "%.2f", minimumVisibleAmount))"
        } else {
            return "$\(enteredDisplayValue)"
        }
    }
    
    private func makeToolbarSecondaryButtonTitle(state: TokenBuyFeature.State) -> String {
        switch state.toolbarSecondaryButtonState {
        case .topUp:
            return "Top up"
        case .useMax:
            return "Use max"
        }
    }
    
    private func makeInputFooter(state: TokenBuyFeature.State) -> TokenNumpadViewFooterState? {
        guard state.isInputAmountAboveZero else {
            return nil
        }
        
        // Show Jupiter quote if available
        if let quote = state.swapQuote {
            // Use the token's actual decimals to convert from smallest unit
            let tokensAmount = (Double(quote.outAmount) ?? 0) / pow(10.0, Double(state.tokenDecimals))
            let formattedTokens = formatTokensAmount(tokensAmount)
            
            return TokenNumpadViewFooterState(
                leadingText: "~\(formattedTokens)",
                leadingTextDouble: tokensAmount,
                trailingText: state.displayTokenName
            )
        }
        
        // Show loading state while fetching quote
        if state.isLoadingQuote {
            return TokenNumpadViewFooterState(
                leadingText: "Fetching quote...",
                leadingTextDouble: 0,
                trailingText: nil
            )
        }
        
        // Show error if quote failed
        if state.quoteError != nil {
            return TokenNumpadViewFooterState(
                leadingText: "Unable to fetch quote",
                leadingTextDouble: 0,
                trailingText: nil
            )
        }
        
        // Fallback to local calculation
        guard state.buyTokensAmountWithFee.value > 0 else {
            return nil
        }
        
        let tokensAmount = Double(state.buyTokensAmountWithFee.value) / Double(Token.fractional.precision)
        let formattedTokens = formatTokensAmount(tokensAmount)
        
        return TokenNumpadViewFooterState(
            leadingText: "~\(formattedTokens)",
            leadingTextDouble: tokensAmount,
            trailingText: state.displayTokenName
        )
    }
    
    private func formatTokensAmount(_ amount: Double) -> String {
        if amount >= 1_000_000 {
            return String(format: "%.2fM", amount / 1_000_000)
        } else if amount >= 1_000 {
            return String(format: "%.2fK", amount / 1_000)
        } else {
            return String(format: "%.2f", amount)
        }
    }
}

// MARK: - String Extensions

private extension String {
    var digitsWithDots: String {
        self.filter { $0.isNumber || $0 == "." }
    }
}

