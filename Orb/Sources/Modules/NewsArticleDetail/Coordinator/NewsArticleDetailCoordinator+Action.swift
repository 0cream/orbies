import ComposableArchitecture

extension NewsArticleDetailCoordinator {
    @CasePathable
    enum Action {
        enum Delegate {
            case didFinish
        }
        
        case root(NewsArticleDetailFeature.Action)
        case delegate(Delegate)
    }
}

