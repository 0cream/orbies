import ComposableArchitecture

extension OnboardingFeature {
    @CasePathable
    enum Action: ViewAction {
        enum View {
            case didAppear
            case didTapNext
            case didTapSkip
        }
        
        enum Reducer {
            case showFirstLine
            case showSecondLine
            case textAnimationCompleted
            case changePage(Int)
            case showOrbLogo
            case scaleBackOrbLogo
            case showNotification1
            case showNotification2
            case showNotification3
            case showNotification4
            case showNotification5
            case showNotification6
            case showNotification7
            case showNotification8
            case showNotification9
            case showNotification10
        }
        
        enum Delegate {
            case didComplete
        }
        
        case view(View)
        case reducer(Reducer)
        case delegate(Delegate)
    }
}

