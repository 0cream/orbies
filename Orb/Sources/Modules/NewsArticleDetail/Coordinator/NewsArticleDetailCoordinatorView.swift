import ComposableArchitecture
import SwiftUI

struct NewsArticleDetailCoordinatorView: View {
    
    let store: StoreOf<NewsArticleDetailCoordinator>
    
    var body: some View {
        NewsArticleDetailView(store: store.scope(state: \.root, action: \.root))
    }
}

