import ComposableArchitecture

extension MaintenanceMainFeature {
    @CasePathable
    enum Action: ViewAction {
        enum View {
            // TODO: - Add view actions
        }
        
        enum Reducer {
            // TODO: - Add reducer actions
        }
        
        enum Delegate {
            case didFinish
        }
        
        case view(View)
        case reducer(Reducer)
        case delegate(Delegate)
    }
} 