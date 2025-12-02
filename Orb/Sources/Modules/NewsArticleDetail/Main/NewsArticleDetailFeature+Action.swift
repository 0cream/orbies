import ComposableArchitecture

extension NewsArticleDetailFeature {
    @CasePathable
    enum Action: ViewAction {
        enum View {
            case didTapClose
        }
        
        enum Delegate {
            case didFinish
        }
        
        case view(View)
        case delegate(Delegate)
    }
}

