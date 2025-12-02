import ComposableArchitecture

extension TransactionDetailFeature {
    @CasePathable
    enum Action: ViewAction {
        enum View {
            case didTapClose
            case didTapCopySignature
        }
        
        enum Delegate {
            case didFinish
        }
        
        case view(View)
        case delegate(Delegate)
    }
}

