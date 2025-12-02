import ComposableArchitecture

extension TokenSellCoordinator {
    @ObservableState
    struct State {
        var path = StackState<Path.State>()
        var root: TokenSellFeature.State
        @Presents var destination: Destination.State?
    }
}

