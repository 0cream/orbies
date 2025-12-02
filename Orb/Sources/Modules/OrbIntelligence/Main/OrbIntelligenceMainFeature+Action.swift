import ComposableArchitecture

extension OrbIntelligenceMainFeature {
    @CasePathable
    enum Action: ViewAction, BindableAction {
        enum View {
            case onAppear
            case didChangeInput(String)
            case didTapSuggest(String)
            case didTapSend
        }
        
        enum Reducer {
            case didRequestPreInput
            case setupObservers
            case didUpdateMessages([OrbMessage])
            case didUpdateSuggests([String])
            case didFinishSendMessage
        }
        
        enum Delegate {
            // Future delegate actions
        }
        
        case binding(BindingAction<State>)
        case view(View)
        case reducer(Reducer)
        case delegate(Delegate)
    }
}

