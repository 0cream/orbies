import ComposableArchitecture

extension PortfolioCoordinator {
    @ObservableState
    struct State {
        var path = StackState<Path.State>()
        var root: PortfolioMainFeature.State
        @Presents var destination: Destination.State?
        
        init(root: PortfolioMainFeature.State = PortfolioMainFeature.State()) {
            self.root = root
        }
    }
}

