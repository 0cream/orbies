import ComposableArchitecture

extension TokenSellCoordinator {
    @CasePathable
    enum Action {
        enum Delegate {
            case didFinish(usdcAmount: Double, tokenTicker: String)
            case didFail(error: String)
            case didRequestSell(
                tokenName: String,
                tokensAmount: Token,
                usdcAmount: Usdc,
                usdAmount: Usd,
                fee: Usdc
            )
        }
        
        case path(StackActionOf<Path>)
        case destination(PresentationAction<Destination.Action>)
        case root(TokenSellFeature.Action)
        case delegate(Delegate)
    }
}

extension TokenSellCoordinator {
    @Reducer
    enum Path {
        // Add nested routes here if needed
    }
}

extension TokenSellCoordinator {
    @Reducer
    enum Destination {
        // Add modal destinations here if needed
    }
}

