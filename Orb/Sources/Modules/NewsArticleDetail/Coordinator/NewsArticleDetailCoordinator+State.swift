import ComposableArchitecture

extension NewsArticleDetailCoordinator {
    @ObservableState
    struct State {
        var root: NewsArticleDetailFeature.State
        
        init(root: NewsArticleDetailFeature.State) {
            self.root = root
        }
    }
}

