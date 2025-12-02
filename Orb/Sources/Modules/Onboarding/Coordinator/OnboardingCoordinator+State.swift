import ComposableArchitecture

extension OnboardingCoordinator {
    @ObservableState
    struct State {
        var path = StackState<Path.State>()
        var root = OnboardingFeature.State()
        
        @Presents var destination: Destination.State?
    }
}

