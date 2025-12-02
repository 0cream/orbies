import ComposableArchitecture

extension DebugFeature {
    @ObservableState
    struct State {
        var isClearing: Bool = false
        var lastAction: String = ""
        
        // Debug Toggles
        var showOnboarding: Bool = true
        var showAuth: Bool = true
        
        // News Events Update
        var eventsJSON: String = ""
        var isUpdatingEvents: Bool = false
    }
}

