import ComposableArchitecture

extension AccountActivationFeature {
    @CasePathable
    enum Action: ViewAction {
        enum View {
            case didAppear
            case accountActivated
        }
        
        enum Delegate {
            case didComplete
        }
        
        case view(View)
        case delegate(Delegate)
    }
}


