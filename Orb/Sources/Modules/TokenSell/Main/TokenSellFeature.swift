import Foundation
import ComposableArchitecture

@Reducer
struct TokenSellFeature {
    @Dependency(\.hapticFeedbackGenerator) var hapticFeedback
    @Dependency(\.tradingCalculationService) var tradingCalculation
    @Dependency(\.userService) var userService
    @Dependency(\.jupiterService) var jupiterService
    @Dependency(\.walletService) var walletService
    @Dependency(\.heliusService) var heliusService
    @Dependency(\.continuousClock) var clock
    
    private enum CancelID { 
        case quoteRefresh
        case debounceInput
        case transactionPolling
    }
    
    var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case let .view(viewAction):
                return handleViewAction(viewAction, state: &state)
                
            case let .reducer(reducerAction):
                return handleReducerAction(reducerAction, state: &state)
                
            case .delegate:
                return .none
            }
        }
    }
    
    // MARK: - View Actions
    
    private func handleViewAction(_ action: Action.View, state: inout State) -> Effect<Action> {
        switch action {
        case .onAppear:
            // TODO: Add analytics
            updateUsdcAmounts(state: &state)
            return .merge(
                // Fetch USDC balance
                .run { [userService] send in
                    let balance = await userService.getUsdcBalance()
                    await send(.reducer(.didUpdateBalance(balance)))
                    
                    // Simulate fetching fee
                    try await Task.sleep(for: .milliseconds(500))
                    await send(.reducer(.didUpdateFee(.mock)))
                },
                // Start periodic quote refresh timer (every 5 seconds)
                .run { [clock] send in
                    for await _ in clock.timer(interval: .seconds(5)) {
                        await send(.reducer(.refreshQuoteTimerTick))
                    }
                }
                .cancellable(id: CancelID.quoteRefresh)
            )
            
        case let .didChangeValue(input):
            let valueChangeEffect = didChangeValue(input: input, state: &state)
            
            // Debounced quote fetch when input changes
            let debounceEffect: Effect<Action> = .run { [state, jupiterService, walletService] send in
                // Wait 500ms before fetching quote (debounce)
                try await Task.sleep(for: .milliseconds(500))
                
                // Only fetch if amount is above zero
                guard state.sellTokensAmount.value > .zero else { return }
                
                await send(.reducer(.didUpdateSwapQuote(
                    await Result {
                        try await fetchSellSwapQuote(
                            state: state,
                            jupiterService: jupiterService,
                            walletService: walletService
                        )
                    }
                )))
            }
            .cancellable(id: CancelID.debounceInput, cancelInFlight: true)
            
            return .merge(valueChangeEffect, debounceEffect)
            
        case .didTapToolbarSecondaryButton:
            // Not used in sell screen
            return .none
            
        case .didTapActionButton:
            guard state.isEnoughBalance && state.isInputAmountAboveZero else {
                return .none
            }
            
            // Check if we have a swap quote from Jupiter
            guard let swapQuote = state.swapQuote else {
                // Fallback: send old delegate for backward compatibility
                return .send(
                    .delegate(
                        .didRequestSell(
                            tokenName: state.displayTokenName,
                            tokensAmount: state.sellTokensAmount,
                            usdcAmount: state.sellTokensAmountInUsdc,
                            usdAmount: Usd(usd: state.sellTokensAmountInUsdcWithFee.USDC),
                            fee: state.fee
                        )
                    )
                )
            }
            
            // Execute the swap via Jupiter Ultra
            state.isExecutingSwap = true
            print("💰 Executing sell swap for \(state.displayTokenName)...")
            
            return .run { [jupiterService, heliusService] send in
                await send(.reducer(.didSendTransaction(
                    await Result {
                        // 1. Sign transaction via JupiterService
                        let signedTxBase58 = try await jupiterService.signUltraSwapTransaction(order: swapQuote)
                        // 2. Send transaction via HeliusService
                        let signature = try await heliusService.sendTransaction(signedTransactionBase58: signedTxBase58)
                        return signature
                    }
                )))
            }
            
        case let .didTapToolbarItem(id):
            guard let action = state.toolbarSecondaryActions.first(where: { $0.type.rawValue == id }) else {
                return .run { _ in
                    await hapticFeedback.error()
                }
            }
            
            let updatedValue = state.tokensBalance.units
                .multiplying(by: NSDecimalNumber(value: action.multiplier))
            
            guard updatedValue > .zero else {
                state.balanceShakeIdentifier = UUID()
                return .run { _ in
                    await hapticFeedback.error()
                }
            }
            
            let formatter = NumberFormatter()
            formatter.numberStyle = .decimal
            formatter.maximumFractionDigits = 6
            formatter.decimalSeparator = "."
            formatter.roundingMode = .down
            formatter.groupingSeparator = ""
            
            let newInput = formatter.string(from: updatedValue) ?? state.input
            return didChangeValue(input: newInput, state: &state)
        }
    }
    
    // MARK: - Reducer Actions
    
    private func handleReducerAction(_ action: Action.Reducer, state: inout State) -> Effect<Action> {
        switch action {
        case let .didUpdateBalance(balance):
            state.balance = balance
            return .none
            
        case let .didUpdateTokenBalance(tokenBalance):
            state.tokensBalance = tokenBalance
            updateUsdcAmounts(state: &state)
            return .none
            
        case let .didUpdateFee(feeAmount):
            state.feeAmount = feeAmount
            return .none
            
        case let .didUpdateTokenReserves(reserves):
            state.tokenReserves = reserves
            updateUsdcAmounts(state: &state)
            return .none
            
        case let .didUpdateSwapQuote(result):
            state.isLoadingQuote = false
            switch result {
            case .success(let quote):
                // Check if the quote has an error (e.g., "Insufficient funds")
                if let error = quote.error ?? quote.errorMessage {
                    state.quoteError = error
                    state.swapQuote = nil
                    print("⚠️ TokenSell: Quote returned with error: \(error)")
                } else {
                    state.swapQuote = quote
                    state.quoteError = nil
                    state.lastQuoteUpdateTime = Date()
                    print("✅ TokenSell: Updated swap quote")
                    print("   Output: \(quote.outAmount) USDC")
                    if let priceImpact = quote.priceImpact {
                        print("   Price Impact: \(priceImpact)%")
                    }
                }
                
            case .failure(let error):
                state.quoteError = error.localizedDescription
                print("❌ TokenSell: Failed to fetch quote: \(error)")
            }
            return .none
            
        case .refreshQuoteTimerTick:
            // Only refresh if we have an amount and not already loading
            guard state.sellTokensAmount.value > .zero, !state.isLoadingQuote else {
                return .none
            }
            
            state.isLoadingQuote = true
            return .run { [state, jupiterService, walletService] send in
                await send(.reducer(.didUpdateSwapQuote(
                    await Result {
                        try await fetchSellSwapQuote(
                            state: state,
                            jupiterService: jupiterService,
                            walletService: walletService
                        )
                    }
                )))
            }
            
        case let .didSendTransaction(result):
            switch result {
            case .success(let signature):
                print("✅ Transaction sent! Signature: \(signature)")
                state.executingTransactionSignature = signature
                
                // Start polling for confirmation
                return .run { [heliusService, clock] send in
                    for _ in 0..<60 { // Poll for up to 60 seconds
                        await send(.reducer(.checkTransactionStatus))
                        try await clock.sleep(for: .seconds(1))
                    }
                }
                .cancellable(id: CancelID.transactionPolling)
                
            case .failure(let error):
                print("❌ Transaction failed: \(error)")
                state.isExecutingSwap = false
                state.executingTransactionSignature = nil
                return .send(.delegate(.didFail(error: error.localizedDescription)))
            }
            
        case .checkTransactionStatus:
            guard let signature = state.executingTransactionSignature else {
                return .none
            }
            
            return .run { [heliusService] send in
                await send(.reducer(.didUpdateTransactionStatus(
                    await Result {
                        let statuses = try await heliusService.getSignatureStatuses(signatures: [signature])
                        return statuses.first ?? nil
                    }
                )))
            }
            
        case let .didUpdateTransactionStatus(result):
            switch result {
            case .success(let status):
                if let status = status, status.isConfirmed {
                    print("✅ Transaction confirmed!")
                    state.isExecutingSwap = false
                    state.executingTransactionSignature = nil
                    
                    // Calculate USDC amount from swap quote
                    let usdcAmount: Double
                    if let quote = state.swapQuote {
                        usdcAmount = (Double(quote.outAmount) ?? 0) / pow(10.0, 6.0) // USDC has 6 decimals
                    } else {
                        usdcAmount = 0
                    }
                    
                    return .merge(
                        .cancel(id: CancelID.transactionPolling),
                        .send(.delegate(.didFinish(usdcAmount: usdcAmount, tokenTicker: state.tokenTicker)))
                    )
                }
                // Keep waiting for confirmation
                return .none
                
            case .failure(let error):
                print("❌ Failed to check transaction status: \(error)")
                // Keep trying
                return .none
            }
        }
    }
    
    // MARK: - Helpers
    
    private func didChangeValue(input: String, state: inout State) -> Effect<Action> {
        let inputAmount = Token(units: Double(input.digitsWithDots) ?? 0.0)
        
        guard inputAmount.units < NSDecimalNumber(value: 10_000_000_000) else {
            state.inputShakeIdentifier = UUID()
            return .run { _ in
                await hapticFeedback.error()
            }
        }
        
        state.input = formatInputStringValue(input: input, current: state.input)
        state.sellTokensAmount = inputAmount
        
        updateUsdcAmounts(state: &state)
        
        return .none
    }
    
    private func updateUsdcAmounts(state: inout State) {
        guard let tokenReserves = state.tokenReserves else {
            state.tokensBalanceInUsdc = .zero
            state.sellTokensAmountInUsdc = .zero
            return
        }
        
        state.tokensBalanceInUsdc = tradingCalculation.sellAmount(
            amount: state.tokensBalance,
            tokenReserves: tokenReserves
        )
        
        state.sellTokensAmountInUsdc = tradingCalculation.sellAmount(
            amount: state.sellTokensAmount,
            tokenReserves: tokenReserves
        )
    }
}

// MARK: - Helpers

private func fetchSellSwapQuote(
    state: TokenSellFeature.State,
    jupiterService: JupiterService,
    walletService: WalletService
) async throws -> JupiterUltraOrder {
    // Get wallet address
    let taker = try await walletService.getPublicKey()
    
    // USDC mint address (6 decimals)
    let usdcMint = "EPjFWdd5AufqSSqeM2qN1xzybapC8G4wEGGkZwyTDt1v"
    
    // Get token mint from state
    let tokenMint = state.tokenMintAddress
    
    // Convert token amount to smallest unit using the token's actual decimals
    let amountInSmallestUnit = String(Int(state.sellTokensAmount.units.doubleValue * pow(10.0, Double(state.tokenDecimals))))
    
    print("🪐 Fetching sell quote:")
    print("   Input: \(state.sellTokensAmount.units.doubleValue) tokens (\(amountInSmallestUnit) smallest units)")
    print("   Token decimals: \(state.tokenDecimals)")
    
    // Fetch quote from Jupiter Ultra API (selling tokens for USDC)
    let quote = try await jupiterService.getSwapOrder(
        inputMint: tokenMint,
        outputMint: usdcMint,
        amount: amountInSmallestUnit,
        taker: taker,
        slippageBps: 50 // 0.5% slippage
    )
    
    return quote
}

// MARK: - Helpers

private func formatInputStringValue(input: String, current: String) -> String {
    if input == "" {
        return "0"
    } else if current == "0" && input != "0." && abs(input.count - current.count) == 1 {
        return String(input.suffix(1))
    } else {
        return input
    }
}

private extension String {
    var digitsWithDots: String {
        self.filter { $0.isNumber || $0 == "." }
    }
}

extension NSDecimalNumber: Comparable {
    public static func < (lhs: NSDecimalNumber, rhs: NSDecimalNumber) -> Bool {
        return lhs.compare(rhs) == .orderedAscending
    }
}
