import ComposableArchitecture

extension OrbIntelligenceCoordinator {
    @ObservableState
    struct State {
        var root: OrbIntelligenceMainFeature.State
        
        init(root: OrbIntelligenceMainFeature.State = OrbIntelligenceMainFeature.State()) {
            self.root = root
        }
    }
}

