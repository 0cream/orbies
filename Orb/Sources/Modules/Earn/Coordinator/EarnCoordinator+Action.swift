import ComposableArchitecture

extension EarnCoordinator {
    @CasePathable
    enum Action {
        enum Delegate {
            case didFinish
        }
        
        case path(StackActionOf<Path>)
        case main(EarnMainFeature.Action)
        case delegate(Delegate)
    }
}

extension EarnCoordinator {
    @Reducer
    enum Path {
        // Empty - Portfolio handles all navigation from Earn
    }
}

