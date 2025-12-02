import ComposableArchitecture

extension WalletImportCoordinator {
    
    @ObservableState
    struct State {
        var root: WalletImportFeature.State
        var path: StackState<Path.State>
        @Presents var destination: Destination.State?
        
        init() {
            self.root = WalletImportFeature.State()
            self.path = StackState()
        }
    }
    
    @Reducer
    enum Destination {
        // Add destination screens if needed
    }
}

