import ComposableArchitecture

extension ExploreMainFeature {
    @ObservableState
    struct State {
        var topTradedTokens: [JupiterVerifiedToken] = []
        var isLoading: Bool = false
        var errorMessage: String?
    }
}

