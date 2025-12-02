import ComposableArchitecture
import AuthenticationServices

extension AuthMainFeature {
    @CasePathable
    enum Action: ViewAction {
        enum View {
            case didTapContinueWithEmail
            case didTapPrivateKey
        }
        
        enum Reducer {
            case requestAuth(provider: AuthProvider)
            case didFailedAuthorization(Error)
            case didSuccessAuthorization
        }
        
        enum Delegate {
            case didTapPrivateKey
            case didRequestAuth(provider: AuthProvider)
        }
        
        case view(View)
        case reducer(Reducer)
        case delegate(Delegate)
    }
} 
