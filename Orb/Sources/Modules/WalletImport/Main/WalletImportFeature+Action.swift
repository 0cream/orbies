import ComposableArchitecture

extension WalletImportFeature {
    @CasePathable
    enum Action: ViewAction {
        enum View {
            case didAppear
            case didTapBack
            case privateKeyChanged(String)
            case didTapNext
            case importSuccess
            case importFailed(String)
        }
        
        enum Delegate {
            case didClose
            case didComplete
        }
        
        case view(View)
        case delegate(Delegate)
    }
}


