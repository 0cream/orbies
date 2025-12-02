import ComposableArchitecture

extension DebugCoordinator {
    @CasePathable
    enum Action: ViewAction {
        enum View {
            case didTapClose
        }
        
        enum Reducer {
        }
        
        enum Delegate {
        }
        
        case view(View)
        case reducer(Reducer)
        case delegate(Delegate)
        case root(DebugFeature.Action)
    }
}

