import ComposableArchitecture

extension DebugCoordinator {
    @ObservableState
    struct State {
        var root: DebugFeature.State
        
        init() {
            self.root = DebugFeature.State()
        }
    }
}

