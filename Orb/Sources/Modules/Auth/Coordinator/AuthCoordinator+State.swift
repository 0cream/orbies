import ComposableArchitecture

extension AuthCoordinator {
    @ObservableState
    struct State {
        var path = StackState<Path.State>()
        var root = AuthMainFeature.State()
    }
} 
