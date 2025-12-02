import ComposableArchitecture

extension ExploreCoordinator {
    @ObservableState
    struct State {
        var path = StackState<Path.State>()
        var main: ExploreMainFeature.State = .init()
    }
}

