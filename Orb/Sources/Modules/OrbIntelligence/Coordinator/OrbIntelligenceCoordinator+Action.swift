import ComposableArchitecture

extension OrbIntelligenceCoordinator {
    @CasePathable
    enum Action {
        enum Delegate {
            // Future delegate actions
        }
        
        case root(OrbIntelligenceMainFeature.Action)
        case delegate(Delegate)
    }
}

