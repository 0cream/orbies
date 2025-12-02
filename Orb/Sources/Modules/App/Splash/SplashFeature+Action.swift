import ComposableArchitecture

extension SplashFeature {
    @CasePathable
    enum Action: ViewAction {
        enum View {
            case onAppear
        }
        
        enum Reducer {
        }
        
        enum Delegate {
            case didCompleteWithWallet
            case didCompleteWithoutWallet
            case didRequestMaintenance
        }
        
        case view(View)
        case reducer(Reducer)
        case delegate(Delegate)
    }
} 
