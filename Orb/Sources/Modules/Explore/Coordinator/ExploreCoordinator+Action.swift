import ComposableArchitecture

extension ExploreCoordinator {
    @CasePathable
    enum Action {
        case main(ExploreMainFeature.Action)
        case path(StackActionOf<Path>)
    }
}

extension ExploreCoordinator {
    @Reducer
    enum Path {
        case tokenDetails(TokenDetailsCoordinator)
    }
}

