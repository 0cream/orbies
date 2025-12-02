import ComposableArchitecture

extension EarnCoordinator {
    @ObservableState
    struct State {
        var path = StackState<Path.State>()
        var main: EarnMainFeature.State
        
        init(main: EarnMainFeature.State = EarnMainFeature.State()) {
            self.main = main
        }
    }
}

