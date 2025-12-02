import SwiftUI
import ComposableArchitecture

struct TokenSellView: View {
    @Bindable var store: StoreOf<TokenSellFeature>
    
    var body: some View {
        TokenNumpadView(
            viewModel: TokenSellViewModel(store: store),
            viewStateTransformer: TokenSellStateTransformer()
        )
    }
}

// MARK: - ViewModel Adapter

/// Adapter to make TCA Store conform to TokenNumpadViewModelProtocol
final class TokenSellViewModel: ObservableObject, TokenNumpadViewModelProtocol {
    typealias State = TokenSellFeature.State
    
    private let store: StoreOf<TokenSellFeature>
    
    var state: State {
        store.state
    }
    
    init(store: StoreOf<TokenSellFeature>) {
        self.store = store
    }
    
    func send(_ action: TokenNumpadViewAction, animation: Animation?) {
        let viewAction: TokenSellFeature.Action.View
        
        switch action {
        case .onAppear:
            viewAction = .onAppear
        case let .didChangeValue(value):
            viewAction = .didChangeValue(value)
        case .didTapToolbarSecondaryButton:
            viewAction = .didTapToolbarSecondaryButton
        case let .didTapToolbarItem(id):
            viewAction = .didTapToolbarItem(id: id)
        case .didTapActionButton:
            viewAction = .didTapActionButton
        }
        
        if let animation = animation {
            store.send(.view(viewAction), animation: animation)
        } else {
            store.send(.view(viewAction))
        }
    }
}

