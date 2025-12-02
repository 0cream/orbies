import ComposableArchitecture

extension MaintenanceCoordinator {
    @CasePathable
    enum Action {
        enum Delegate {
            // delegate actions
        }
        
        case path(StackActionOf<Path>)
        case destination(PresentationAction<Destination.Action>)
        case root(MaintenanceMainFeature.Action)
        case delegate(Delegate)
    }
}

extension MaintenanceCoordinator {
    @Reducer
    enum Path {
        // - example:
        // case splash(SplashFeature)
    }
} 

extension MaintenanceCoordinator {
    @Reducer
    enum Destination {
        //
    }
} 
