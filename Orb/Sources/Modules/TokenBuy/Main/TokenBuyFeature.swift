import Foundation
import ComposableArchitecture

@Reducer
struct TokenBuyFeature {
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
                guard state.buyUsdcAmount > .zero else { return }
                
                await send(.reducer(.didUpdateSwapQuote(
                    await Result {
                        try await fetchSwapQuote(
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
            switch state.toolbarSecondaryButtonState {
            case .topUp:
                // TODO: Add analytics
                if state.buyUsdcAmount.value == 0 {
                    return .send(.delegate(.didRequestTopUp(amount: nil)))
                } else {
                    let minimumTopup = Usdc(value: max(0, state.buyUsdcAmount.value - state.availableBalance.value))
                    return .send(.delegate(.didRequestTopUp(amount: minimumTopup)))
                }
                
            case .useMax:
                // TODO: Add analytics
                state.input = formatUsdc(state.availableBalance)
                state.buyUsdAmount = Usd(usd: state.availableBalance.USDC)
                state.buyUsdcAmount = state.availableBalance
                return .none
            }
            
        case .didTapActionButton:
            guard state.isEnoughBalance && state.isInputAmountAboveZero else {
                if state.buyUsdcAmount > .zero {
                    let topUpAmount = Usdc(value: state.buyUsdcAmount.value - state.availableBalance.value)
                    return .send(.delegate(.didRequestTopUp(amount: topUpAmount)))
                } else {
                    return .send(.delegate(.didRequestTopUp(amount: nil)))
                }
            }
            
            // Check if we have a swap quote from Jupiter
            guard let swapQuote = state.swapQuote else {
                // Fallback: send old delegate for backward compatibility
                return .send(
                    .delegate(
                        .didRequestPurchase(
                            tokenName: state.displayTokenName,
                            tokensAmount: state.buyTokensAmount,
                            tokensAmountWithFee: state.buyTokensAmountWithFee,
                            usdcAmount: state.buyUsdcAmount,
                            usdAmount: state.buyUsdAmount,
                            fee: state.fee
                        )
                    )
                )
            }
            
            // Execute the swap via Jupiter Ultra
            state.isExecutingSwap = true
            print("💰 Executing swap for \(state.displayTokenName)...")
            
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
            
        case .didTapToolbarItem:
            // For future use (e.g., selecting different payment methods)
            return .none
        }
    }
    
    // MARK: - Reducer Actions
    
    private func handleReducerAction(_ action: Action.Reducer, state: inout State) -> Effect<Action> {
        switch action {
        case let .didUpdateBalance(balance):
            state.balance = balance
            updateTokenAmounts(state: &state)
            return .none
            
        case let .didUpdateFee(feeAmount):
            state.feeAmount = feeAmount
            updateTokenAmounts(state: &state)
            return .none
            
        case let .didUpdateTokenReserves(reserves):
            state.tokenReserves = reserves
            updateTokenAmounts(state: &state)
            return .none
            
        case let .didUpdateSwapQuote(result):
            state.isLoadingQuote = false
            switch result {
            case .success(let quote):
                // Check if the quote has an error (e.g., "Insufficient funds")
                if let error = quote.error ?? quote.errorMessage {
                    state.quoteError = error
                    state.swapQuote = nil
                    print("⚠️ TokenBuy: Quote returned with error: \(error)")
                } else {
                    state.swapQuote = quote
                    state.quoteError = nil
                    state.lastQuoteUpdateTime = Date()
                    print("✅ TokenBuy: Updated swap quote")
                    print("   Output: \(quote.outAmount) tokens")
                    if let priceImpact = quote.priceImpact {
                        print("   Price Impact: \(priceImpact)%")
                    }
                }
                
            case .failure(let error):
                state.quoteError = error.localizedDescription
                print("❌ TokenBuy: Failed to fetch quote: \(error)")
            }
            return .none
            
        case .refreshQuoteTimerTick:
            // Only refresh if we have an amount and not already loading
            guard state.buyUsdcAmount > .zero, !state.isLoadingQuote else {
                return .none
            }
            
            state.isLoadingQuote = true
            return .run { [state, jupiterService, walletService] send in
                await send(.reducer(.didUpdateSwapQuote(
                    await Result {
                        try await fetchSwapQuote(
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
                    
                    // Calculate token amount from swap quote
                    let tokenAmount: Double
                    if let quote = state.swapQuote {
                        tokenAmount = (Double(quote.outAmount) ?? 0) / pow(10.0, Double(state.tokenDecimals))
                    } else {
                        tokenAmount = 0
                    }
                    
                    return .merge(
                        .cancel(id: CancelID.transactionPolling),
                        .send(.delegate(.didFinish(tokenAmount: tokenAmount, tokenTicker: state.tokenTicker)))
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
        let inputUsd = Usd(usd: Double(input.digitsWithDots) ?? 0.0)
        
        guard inputUsd.USD < 100_000_000 else {
            state.inputShakeIdentifier = UUID()
            return .run { _ in
                await hapticFeedback.error()
            }
        }
        
        state.input = formatUsdInputStringValue(input: input, current: state.input)
        
        // Convert USD to USDC (1:1 for now)
        let inputUsdc = Usdc(usdc: inputUsd.USD)
        
        state.buyUsdAmount = inputUsd
        state.buyUsdcAmount = inputUsdc
        
        updateTokenAmounts(state: &state)
        
        return .none
    }
    
    private func updateTokenAmounts(state: inout State) {
        guard let tokenReserves = state.tokenReserves else {
            state.buyTokensAmount = .zero
            state.buyTokensAmountWithFee = .zero
            return
        }
        
        state.buyTokensAmount = tradingCalculation.buyAmount(
            amount: state.buyUsdcAmount,
            tokenReserves: tokenReserves
        )
        
        let usdcAfterFee = Usdc(value: max(0, state.buyUsdcAmount.value - state.fee.value))
        state.buyTokensAmountWithFee = tradingCalculation.buyAmount(
            amount: usdcAfterFee,
            tokenReserves: tokenReserves
        )
    }
    
    private func formatUsdc(_ usdc: Usdc) -> String {
        "$\(String(format: "%.2f", usdc.USDC))"
    }
}

// MARK: - Helpers

private func fetchSwapQuote(
    state: TokenBuyFeature.State,
    jupiterService: JupiterService,
    walletService: WalletService
) async throws -> JupiterUltraOrder {
    // Get wallet address
    let taker = try await walletService.getPublicKey()
    
    // USDC mint address (6 decimals)
    let usdcMint = "EPjFWdd5AufqSSqeM2qN1xzybapC8G4wEGGkZwyTDt1v"
    
    // Get token mint from state
    let tokenMint = state.tokenMintAddress
    
    // Convert USDC amount to smallest unit (USDC always has 6 decimals)
    let usdcDecimals = 6
    let amountInSmallestUnit = String(Int(state.buyUsdcAmount.USDC * pow(10.0, Double(usdcDecimals))))
    
    print("🪐 Fetching buy quote:")
    print("   Input: \(state.buyUsdcAmount.USDC) USDC (\(amountInSmallestUnit) smallest units)")
    print("   Token decimals: \(state.tokenDecimals)")
    
    // Fetch quote from Jupiter Ultra API
    let quote = try await jupiterService.getSwapOrder(
        inputMint: usdcMint,
        outputMint: tokenMint,
        amount: amountInSmallestUnit,
        taker: taker,
        slippageBps: 50 // 0.5% slippage
    )
    
    return quote
}

// MARK: - Helpers

private func formatUsdInputStringValue(input: String, current: String) -> String {
    if input == "$" {
        return "$0"
    } else if current == "$0" && input != "$0." {
        return "$" + String(input.suffix(1))
    } else {
        return input
    }
}

// MARK: - String Extensions

private extension String {
    var digitsWithDots: String {
        self.filter { $0.isNumber || $0 == "." }
    }
}

