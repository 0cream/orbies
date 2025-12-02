import ComposableArchitecture
import Dependencies

@Reducer
struct ExploreMainFeature {
    @Dependency(\.jupiterService) var jupiterService
    @Dependency(\.orbBackendService) var orbBackendService
    
    var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
                
            // MARK: - View Actions
                
            case .view(.didAppear):
                print("🔭 Explore: didAppear called")
                return .send(.reducer(.loadTopTradedTokens))
                
            case .view(.didTapToken(let token)):
                print("🔭 Explore: Tapped token: \(token.symbol)")
                return .send(.delegate(.didRequestTokenDetails(token)))
                
            // MARK: - Reducer Actions
                
            case .reducer(.loadTopTradedTokens):
                guard !state.isLoading else { return .none }
                
                print("🔭 Explore: Loading top traded tokens...")
                state.isLoading = true
                state.errorMessage = nil
                
                return .run { send in
                    do {
                        let tokens = try await jupiterService.getTopTradedTokens(limit: 50)
                        await send(.reducer(.topTradedTokensLoaded(tokens)))
                    } catch {
                        await send(.reducer(.loadingFailed("Failed to load tokens: \(error.localizedDescription)")))
                    }
                }
                
            case .reducer(.topTradedTokensLoaded(let tokens)):
                print("✅ Explore: Loaded \(tokens.count) top traded tokens")
                
                // Debug: Check first few token icons
                for (index, token) in tokens.prefix(3).enumerated() {
                    if let icon = token.icon {
                        print("   Token \(index + 1): \(token.symbol) - Icon URL: \(icon)")
                    } else {
                        print("   Token \(index + 1): \(token.symbol) - No icon URL")
                    }
                }
                
                state.isLoading = false
                state.topTradedTokens = tokens
                
                // Submit tokens to backend for price indexing
                return .run { _ in
                    print("📊 Explore: Submitting \(tokens.count) tokens to backend for indexing...")
                    
                    let tokenRequests = tokens.map { token in
                        TokenIndexRequest(
                            address: token.id,
                            symbol: token.symbol,
                            name: token.name
                        )
                    }
                    
                    // Submit to backend (non-blocking, fire and forget)
                    do {
                        let response = try await orbBackendService.addTokensBatch(tokens: tokenRequests)
                        print("✅ Explore: Backend indexing submitted")
                        print("   Accepted: \(response.data.accepted)")
                        print("   Rejected: \(response.data.rejected)")
                    } catch {
                        print("⚠️ Explore: Failed to submit tokens for indexing: \(error.localizedDescription)")
                        // Don't throw - this is fire and forget
                    }
                }
                
            case .reducer(.loadingFailed(let message)):
                print("❌ Explore: \(message)")
                state.isLoading = false
                state.errorMessage = message
                return .none
                
            // MARK: - Delegate Actions
                
            case .delegate:
                return .none
            }
        }
    }
}

