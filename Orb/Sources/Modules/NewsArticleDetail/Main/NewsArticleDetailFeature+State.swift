import ComposableArchitecture

extension NewsArticleDetailFeature {
    @ObservableState
    struct State: Equatable {
        let article: NewsArticle
    }
}

