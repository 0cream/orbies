import ComposableArchitecture
import CoreGraphics

extension WalletReceiveFeature {
    @CasePathable
    enum Action: ViewAction {
        enum View {
            case didAppear
            case didTapClose
            case didTapCopy
            case didTapShare
        }
        
        enum Reducer {
            case loadWalletAddress
            case walletAddressLoaded(String, CGImage?)
        }
        
        enum Delegate {
            case didClose
        }
        
        case view(View)
        case reducer(Reducer)
        case delegate(Delegate)
    }
}


