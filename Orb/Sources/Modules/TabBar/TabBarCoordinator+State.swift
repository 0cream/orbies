import ComposableArchitecture

extension TabBarCoordinator {
    @ObservableState
    struct State {
        var selectedTab: Tab = .home
        var portfolio = PortfolioCoordinator.State()
        var history = HistoryCoordinator.State()
        var explore = ExploreCoordinator.State()
        var showExitConfirmation: Bool = false
        @Presents var orbIntelligence: OrbIntelligenceCoordinator.State?
        
        enum Tab: Int, Equatable, CaseIterable {
            case home = 0
            case history = 1
            case explore = 2
            case settings = 3
        }
    }
}

