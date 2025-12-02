import ComposableArchitecture

extension TokenBuyCoordinator {
    @CasePathable
    enum Action {
        enum Delegate {
            case didFinish(tokenAmount: Double, tokenTicker: String)
            case didFail(error: String)
            case didRequestPurchase(
                tokenName: String,
                tokensAmount: Token,
                tokensAmountWithFee: Token,
                usdcAmount: Usdc,
                usdAmount: Usd,
                fee: Usdc
            )
            case didRequestTopUp(amount: Usdc?)
        }
        
        case path(StackActionOf<Path>)
        case destination(PresentationAction<Destination.Action>)
        case root(TokenBuyFeature.Action)
        case delegate(Delegate)
    }
}

extension TokenBuyCoordinator {
    @Reducer
    enum Path {
        // Add nested routes here if needed (e.g., top-up flow)
    }
}

extension TokenBuyCoordinator {
    @Reducer
    enum Destination {
        // Add modal destinations here if needed
    }
}

