import ComposableArchitecture

extension HoldingsCoordinator {
    @ObservableState
    struct State {
        var path = StackState<Path.State>()
        var main: HoldingsMainFeature.State
        
        init(main: HoldingsMainFeature.State = HoldingsMainFeature.State()) {
            self.main = main
        }
    }
}

