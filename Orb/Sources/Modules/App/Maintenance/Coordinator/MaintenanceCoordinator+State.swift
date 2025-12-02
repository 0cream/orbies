import ComposableArchitecture

extension MaintenanceCoordinator {
    @ObservableState
    struct State {
        var path = StackState<Path.State>()
        var root = MaintenanceMainFeature.State()
        
        @Presents var destination: Destination.State?
    }
} 
