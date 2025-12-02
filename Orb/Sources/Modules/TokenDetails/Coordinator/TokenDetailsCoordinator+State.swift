import ComposableArchitecture

extension TokenDetailsCoordinator {
    @ObservableState
    struct State {
        var root: TokenDetailsFeature.State
        @Presents var destination: Destination.State?
    }
} 
