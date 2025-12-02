import ComposableArchitecture

extension AccountActivationCoordinator {
    @ObservableState
    struct State: Equatable {
        var root = AccountActivationFeature.State()
    }
}


