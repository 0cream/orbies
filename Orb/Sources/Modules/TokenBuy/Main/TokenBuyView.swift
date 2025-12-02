import SwiftUI
import ComposableArchitecture

struct TokenBuyView: View {
    @Bindable var store: StoreOf<TokenBuyFeature>
    
    var body: some View {
        TokenNumpadView(
            viewModel: TokenBuyViewModel(store: store),
            viewStateTransformer: TokenBuyStateTransformer()
        )
    }
}

// MARK: - ViewModel Adapter

/// Adapter to make TCA Store conform to TokenNumpadViewModelProtocol
final class TokenBuyViewModel: ObservableObject, TokenNumpadViewModelProtocol {
    typealias State = TokenBuyFeature.State
    
    private let store: StoreOf<TokenBuyFeature>
    
    var state: State {
        store.state
    }
    
    init(store: StoreOf<TokenBuyFeature>) {
        self.store = store
    }
    
    func send(_ action: TokenNumpadViewAction, animation: Animation?) {
        let viewAction: TokenBuyFeature.Action.View
        
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

