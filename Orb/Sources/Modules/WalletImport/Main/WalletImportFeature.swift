import ComposableArchitecture
import Dependencies
import Foundation

@Reducer
struct WalletImportFeature {
    
    // MARK: - Dependencies
    
    @Dependency(\.walletService)
    private var walletService: WalletService
    
    @Dependency(\.heliusService)
    private var heliusService: HeliusService
    
    @Dependency(\.transactionHistoryService)
    private var transactionHistoryService: TransactionHistoryService
    
    @Dependency(\.orbBackendService)
    private var orbBackendService: OrbBackendService
    
    @Dependency(\.userService)
    private var userService: UserService
    
    @Dependency(\.portfolioHistoryService)
    private var portfolioHistoryService: PortfolioHistoryService
    
    @Dependency(\.hapticFeedbackGenerator)
    private var hapticFeedbackGenerator: HapticFeedbackGenerator
    
    // MARK: - Body
    
    var body: some Reducer<State, Action> {
        Reduce { state, action in
            switch action {
            case let .view(action):
                return reduce(state: &state, action: action)
                
            case .delegate:
                return .none
            }
        }
    }
    
    // MARK: - Reducer
    
    private func reduce(state: inout State, action: Action.View) -> Effect<Action> {
        switch action {
        case .didAppear:
            return .none
            
        case .didTapBack:
            return .send(.delegate(.didClose))
            
        case let .privateKeyChanged(privateKey):
            state.privateKey = privateKey
            return .none
            
        case .didTapNext:
            guard !state.privateKey.isEmpty else {
                state.errorMessage = "Please enter a private key"
                return .run { _ in
                    await hapticFeedbackGenerator.error()
                }
            }
            
            state.isImporting = true
            state.errorMessage = nil
            
            return .run { [privateKey = state.privateKey] send in
                do {
                    // Delete existing wallet and transaction history (for testing)
                    try? await walletService.deleteWallet()
                    await transactionHistoryService.clearHistory()
                    
                    // Import wallet from private key
                    let address = try await walletService.importWallet(privateKey: privateKey)
                    
                    print("✅ Wallet imported successfully: \(address)")
                    
                    // Fetch first transaction to determine wallet initialization timestamp
                    print("🔍 Fetching first transaction for wallet initialization timestamp...")
                    
                    do {
                        if let firstTx = try await heliusService.getFirstTransaction(address: address),
                           let blockTime = firstTx.blockTime {
                            try await walletService.setInitializationTimestamp(blockTime)
                            print("✅ Wallet initialization timestamp set: \(blockTime)")
                            
                            // Fetch all transaction history from now back to init timestamp
                            print("📜 Starting initial transaction history fetch...")
                            do {
                                try await transactionHistoryService.fetchInitialHistory(
                                    walletAddress: address,
                                    initTimestamp: blockTime
                                )
                                
                                // Submit all historical tokens to backend for indexing
                                // This starts indexing ASAP while user goes through onboarding
                                print("📊 Submitting historical tokens for indexing...")
                                await submitHistoricalTokensForIndexing()
                                
                                // Start background portfolio history fetch with auto-retry
                                // This will keep retrying until backend finishes indexing all tokens
                                print("🔄 Starting background portfolio history fetch...")
                                await portfolioHistoryService.startBackgroundFetch()
                                
                            } catch {
                                print("❌ Failed to fetch transaction history: \(error)")
                                print("   Error details: \(error.localizedDescription)")
                            }
                        } else {
                            print("⚠️ No transactions found or timestamp unavailable, using current time")
                            let currentTime = Int(Date().timeIntervalSince1970)
                            try await walletService.setInitializationTimestamp(currentTime)
                        }
                    } catch {
                        print("❌ Failed to fetch first transaction: \(error)")
                        print("   Using current time as fallback")
                        let currentTime = Int(Date().timeIntervalSince1970)
                        try? await walletService.setInitializationTimestamp(currentTime)
                    }
                    
                    // Fetch real balances from Helius
                    // This updates UserService so Portfolio shows correct balances immediately
                    print("💰 Fetching wallet balances...")
                    await userService.refreshBalances()
                    
                    await hapticFeedbackGenerator.success()
                    await send(.view(.importSuccess))
                    
                } catch {
                    await send(.view(.importFailed(error.localizedDescription)))
                }
            }
            
        case .importSuccess:
            state.isImporting = false
            return .send(.delegate(.didComplete))
            
        case let .importFailed(error):
            state.isImporting = false
            state.errorMessage = error
            return .run { _ in
                await hapticFeedbackGenerator.error()
            }
        }
    }
    
    // MARK: - Private Helpers
    
    /// Submit all tokens from transaction history for price indexing
    /// This is called immediately after wallet import to start indexing ASAP
    private func submitHistoricalTokensForIndexing() async {
        // Get all unique tokens from transaction history
        let allTokens = await transactionHistoryService.getUniqueTokens()
        
        guard !allTokens.isEmpty else {
            print("   No tokens found in history")
            return
        }
        
        print("   Found \(allTokens.count) unique tokens in history")
        
        var tokensToSubmit: [TokenIndexRequest] = []
        
        for tokenAddress in allTokens {
            // Skip USDC (stablecoin, price = $1, doesn't need historical indexing)
            if tokenAddress == "EPjFWdd5AufqSSqeM2qN1xzybapC8G4wEGGkZwyTDt1v" {
                continue
            }
            
            // Add to batch (backend will fetch metadata if needed)
            tokensToSubmit.append(TokenIndexRequest(
                address: tokenAddress,
                symbol: nil,
                name: nil
            ))
        }
        
        guard !tokensToSubmit.isEmpty else {
            print("   No tokens to submit (only USDC found)")
            return
        }
        
        // Submit to backend
        do {
            let result = try await orbBackendService.addTokensBatch(tokens: tokensToSubmit)
            print("✅ Submitted \(tokensToSubmit.count) historical tokens to backend")
            print("   Accepted: \(result.data.accepted)")
            print("   Rejected: \(result.data.rejected)")
            print("   Queue: \(result.queue.length) tokens")
            print("   🎯 Indexing will continue in background while you complete onboarding")
        } catch {
            print("⚠️ Failed to submit historical tokens: \(error)")
            // Don't crash - indexing is optional and will be retried in UserService
        }
    }
}

