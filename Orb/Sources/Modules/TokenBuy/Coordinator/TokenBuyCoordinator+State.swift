import ComposableArchitecture

extension TokenBuyCoordinator {
    @ObservableState
    struct State {
        var path = StackState<Path.State>()
        var root: TokenBuyFeature.State
        @Presents var destination: Destination.State?
    }
}

