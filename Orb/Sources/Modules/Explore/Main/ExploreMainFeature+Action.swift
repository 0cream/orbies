import ComposableArchitecture

extension ExploreMainFeature {
    @CasePathable
    enum Action: ViewAction {
        case view(View)
        case reducer(Reducer)
        case delegate(Delegate)
        
        @CasePathable
        enum View {
            case didAppear
            case didTapToken(JupiterVerifiedToken)
        }
        
        @CasePathable
        enum Reducer {
            case loadTopTradedTokens
            case topTradedTokensLoaded([JupiterVerifiedToken])
            case loadingFailed(String)
        }
        
        @CasePathable
        enum Delegate {
            case didRequestTokenDetails(JupiterVerifiedToken)
        }
    }
}

