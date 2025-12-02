import ComposableArchitecture

extension OnboardingCoordinator {
    @CasePathable
    enum Action {
        enum Delegate {
            case didComplete
        }
        
        case path(StackActionOf<Path>)
        case destination(PresentationAction<Destination.Action>)
        case root(OnboardingFeature.Action)
        case delegate(Delegate)
    }
}

extension OnboardingCoordinator {
    @Reducer
    enum Path {
        // Empty for now - can add screens if needed
    }
}

extension OnboardingCoordinator {
    @Reducer
    enum Destination {
        // Empty for now - can add modals if needed
    }
}

