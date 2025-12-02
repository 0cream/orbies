import ComposableArchitecture

extension HistoryCoordinator {
    @ObservableState
    struct State {
        var path = StackState<Path.State>()
        var root: HistoryMainFeature.State
        @Presents var destination: Destination.State?
        
        init(root: HistoryMainFeature.State = HistoryMainFeature.State()) {
            self.root = root
        }
    }
}

