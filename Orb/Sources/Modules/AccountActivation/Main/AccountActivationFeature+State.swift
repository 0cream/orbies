import ComposableArchitecture

extension AccountActivationFeature {
    @ObservableState
    struct State: Equatable {
        var isActivating: Bool = true
    }
}


