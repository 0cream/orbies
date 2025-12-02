import Foundation

/// Transforms TokenSellFeature.State into TokenNumpadViewState
struct TokenSellStateTransformer: TokenNumpadStateToViewStateTransformerProtocol {
    
    // MARK: - Methods
    
    func transform(_ state: TokenSellFeature.State) -> TokenNumpadViewState {
        let inputFooter = makeInputFooter(state: state)
        let actionButtonTitle = makeActionButtonTitle(state: state)
        let toolbar = TokenNumpadToolbarViewState(
            title: "Your \(state.displayTokenName) balance",
            subtitle: "\(makeTokensBalanceDisplayValue(state: state)) • \(makeUsdcBalance(state: state))",
            subtitleShakeId: state.balanceShakeIdentifier,
            secondaryButton: nil,
            secondaryItems: state.toolbarSecondaryActions.map { action in
                TokenNumpadToolbarViewItem(
                    id: action.type.rawValue,
                    title: makeToolbarSecondaryAction(type: action.type)
                )
            },
            style: makeToolbarStyle(state: state),
            isVisible: state.feeAmount != nil
        )
        
        return TokenNumpadViewState(
            title: "Sell \(state.displayTokenName)",
            input: state.input,
            inputDecimalsLimit: 6,
            inputShakeIdentifier: state.inputShakeIdentifier,
            inputDoubleValue: Double(state.input.digitsWithDots) ?? .zero,
            inputStringValue: state.input,
            inputFooter: inputFooter,
            toolbar: toolbar,
            actionButton: TokenNumpadActionButtonState(
                id: state.actionButtonState.rawValue,
                title: actionButtonTitle,
                titleDouble: state.swapQuote?.outUsdValue ?? state.sellTokensAmountInUsdcWithFee.USDC,
                isEnabled: state.isInputAmountAboveZero && state.isEnoughBalance && state.feeAmount != nil && !state.isExecutingSwap,
                isLoading: state.feeAmount == nil || state.isExecutingSwap
            )
        )
    }
    
    // MARK: - Helpers
    
    private func makeUsdcBalance(state: TokenSellFeature.State) -> String {
        var displayText: String
        
        guard state.tokensBalance.value > .zero else {
            return "$0"
        }
        
        if state.tokensBalanceInUsdc.value > 0 {
            displayText = "$\(String(format: "%.2f", state.tokensBalanceInUsdc.USDC))"
        } else {
            displayText = "<$0"
        }
        
        // Add quote info if available
        if let quote = state.swapQuote {
            let routerName = quote.router.capitalized
            displayText += " • via \(routerName)"
        }
        
        return displayText
    }
    
    private func makeToolbarSecondaryAction(
        type: TokenSellFeature.State.ToolbarSecondaryAction.ToolbarSecondaryActionType
    ) -> String {
        switch type {
        case .max:
            return "Max"
        case .percent25:
            return "25%"
        case .percent50:
            return "50%"
        case .percent75:
            return "75%"
        }
    }
    
    private func makeTokensBalanceDisplayValue(state: TokenSellFeature.State) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = 6
        formatter.decimalSeparator = "."
        formatter.roundingMode = .down
        formatter.groupingSeparator = ","
        
        let balance = Double(state.tokensBalance.value) / Double(Token.fractional.precision)
        return formatter.string(from: NSNumber(value: balance)) ?? "0"
    }
    
    private func makeToolbarStyle(state: TokenSellFeature.State) -> TokenNumpadToolbarViewStyle {
        switch state.actionButtonState {
        case .enterAmount, .youHaveNothingToSell, .sell, .incorrectAmount:
            return .idle
        case .insufficientBalance:
            return .negative
        }
    }
    
    private func makeActionButtonTitle(state: TokenSellFeature.State) -> String {
        switch state.actionButtonState {
        case .enterAmount:
            return "Enter the amount"
            
        case .youHaveNothingToSell:
            return "You have nothing to sell"
            
        case .sell:
            return "Sell for \(makeActionButtonTitleValue(state: state))"
            
        case .insufficientBalance:
            return "Insufficient balance"
            
        case .incorrectAmount:
            return "Incorrect amount"
        }
    }
    
    private func makeActionButtonTitleValue(state: TokenSellFeature.State) -> String {
        // Use quote data if available for more accurate pricing
        let usdcValue: Double
        if let quote = state.swapQuote, let outUsdValue = quote.outUsdValue {
            usdcValue = outUsdValue
        } else {
            usdcValue = state.sellTokensAmountInUsdcWithFee.USDC
        }
        
        return "$\(String(format: "%.2f", usdcValue))"
    }
    
    private func makeInputFooter(state: TokenSellFeature.State) -> TokenNumpadViewFooterState? {
        guard state.isInputAmountAboveZero else {
            return nil
        }
        
        // Show Jupiter quote if available
        if let quote = state.swapQuote {
            // USDC always has 6 decimals
            let usdcDecimals = 6
            let usdcAmount = (Double(quote.outAmount) ?? 0) / pow(10.0, Double(usdcDecimals))
            
            return TokenNumpadViewFooterState(
                leadingText: "$\(String(format: "%.2f", usdcAmount))",
                leadingTextDouble: usdcAmount,
                trailingText: nil
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
        guard state.sellTokensAmountInUsdcWithFee.value > 0 else {
            return nil
        }
        
        let usdcValue = state.sellTokensAmountInUsdcWithFee.USDC
        return TokenNumpadViewFooterState(
            leadingText: "$\(String(format: "%.2f", usdcValue))",
            leadingTextDouble: usdcValue,
            trailingText: nil
        )
    }
}

private extension String {
    var digitsWithDots: String {
        self.filter { $0.isNumber || $0 == "." }
    }
}

