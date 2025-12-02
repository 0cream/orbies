import ComposableArchitecture

extension TokenDetailsCoordinator {
    @CasePathable
    enum Action {
        enum Delegate {
            case didFinish
            case didRequestNavigateToNewsArticle(article: NewsArticle)
        }
        
        case destination(PresentationAction<Destination.Action>)
        case root(TokenDetailsFeature.Action)
        case delegate(Delegate)
    }
} 

extension TokenDetailsCoordinator {
    @Reducer
    enum Destination {
        case tokenBuy(TokenBuyCoordinator)
        case tokenSell(TokenSellCoordinator)
        case walletReceive(WalletReceiveCoordinator)
    }
} 