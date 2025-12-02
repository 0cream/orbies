import ComposableArchitecture
import SwiftNavigation

@Reducer
struct PortfolioCoordinator {
    
    var body: some Reducer<State, Action> {
        Scope(state: \.root, action: \.root) {
            PortfolioMainFeature()
        }
        
        Reduce { state, action in
            switch action {
            case let .root(.delegate(action)):
                return reduce(state: &state, action: action)
                
            case let .path(.element(_, action)):
                return reduce(state: &state, action: action)
                
            case let .destination(.presented(action)):
                return reduce(state: &state, action: action)
                
            case .root, .path, .destination:
                return .none
                
            case .delegate:
                return .none
            }
        }
        .forEach(\.path, action: \.path)
        .ifLet(\.$destination, action: \.destination)
    }
    
    // MARK: - Root
    
    private func reduce(state: inout State, action: PortfolioMainFeature.Action.Delegate) -> Effect<Action> {
        switch action {
        case .didRequestShowReceive:
            state.destination = .walletReceive(WalletReceiveCoordinator.State())
            return .none
            
        case let .didTapSearchResult(result):
            // Dismiss search
            state.root.isSearchActive = false
            state.root.searchQuery = ""
            state.root.searchResults = []
            
            // Navigate to token details
            let tokenItem = TokenItem(
                id: result.address,
                name: result.name ?? result.symbol ?? "Unknown",
                ticker: result.symbol ?? "???",
                imageName: result.logoURI ?? "",
                decimals: result.decimals ?? 6,
                price: result.lastPrice?.price ?? 0,
                priceChange: 0, // Not available in search results
                marketCap: nil,
                liquidity: nil,
                volume24h: nil
            )
            
            state.path.append(.tokenDetails(
                TokenDetailsCoordinator.State(
                    root: TokenDetailsFeature.State(token: tokenItem)
                )
            ))
            
            return .none
            
        case .didRequestNavigateToCash:
            // Show only USDC holdings
            let usdcMint = "EPjFWdd5AufqSSqeM2qN1xzybapC8G4wEGGkZwyTDt1v"
            let cashHoldings = state.root.tokenHoldings.filter { $0.id == usdcMint }
            
            state.path.append(
                .holdings(
                    HoldingsCoordinator.State(
                        main: HoldingsMainFeature.State(
                            title: "Cash",
                            tokenHoldings: cashHoldings
                        )
                    )
                )
            )
            return .none
            
        case .didRequestNavigateToHoldings:
            // Show all tokens EXCEPT USDC (cash is separate) and hSOL (shown in Earn)
            let usdcMint = "EPjFWdd5AufqSSqeM2qN1xzybapC8G4wEGGkZwyTDt1v"
            let hsolMint = "he1iusmfkpAdwvxLNGV8Y1iSbj4rUy6yMhEA3fotn9A"
            let holdings = state.root.tokenHoldings.filter { $0.id != usdcMint && $0.id != hsolMint }
            
            state.path.append(
                .holdings(
                    HoldingsCoordinator.State(
                        main: HoldingsMainFeature.State(tokenHoldings: holdings)
                    )
                )
            )
            return .none
            
        case .didRequestNavigateToEarn:
            state.path.append(
                .earn(
                    EarnCoordinator.State()
                )
            )
            return .none
            
        case let .didRequestNavigateToNewsArticle(article):
            // Navigate to news article detail
            state.path.append(.newsArticleDetail(
                NewsArticleDetailCoordinator.State(
                    root: NewsArticleDetailFeature.State(article: article)
                )
            ))
            return .none
            
        case let .didRequestNavigateToTokenDetails(item):
            let tokenItem = TokenItem(
                id: item.id,
                name: item.title,
                ticker: item.subtitle,
                imageName: item.imageName,
                decimals: item.decimals,
                price: item.price,
                priceChange: item.priceChange,
                marketCap: nil,  // Not available from portfolio data
                liquidity: nil,  // Not available from portfolio data
                volume24h: nil   // Not available from portfolio data
            )
            
            state.path.append(
                .tokenDetails(
                    TokenDetailsCoordinator.State(
                        root: TokenDetailsFeature.State(token: tokenItem)
                    )
                )
            )
            return .none
        }
    }
    
    // MARK: - Path
    
    private func reduce(state: inout State, action: Path.Action) -> Effect<Action> {
        switch action {
        case .holdings(.delegate(.didFinish)):
            state.path.removeLast()
            return .none
            
        case let .holdings(.delegate(.didRequestNavigateToTokenDetails(item))):
            // Handle token details navigation from Holdings
            let tokenItem = TokenItem(
                id: item.id,
                name: item.title,
                ticker: item.subtitle,
                imageName: item.imageName,
                decimals: item.decimals,
                price: item.price,
                priceChange: item.priceChange,
                marketCap: nil,
                liquidity: nil,
                volume24h: nil
            )
            
            state.path.append(
                .tokenDetails(
                    TokenDetailsCoordinator.State(
                        root: TokenDetailsFeature.State(token: tokenItem)
                    )
                )
            )
            return .none
            
        case .holdings:
            return .none
            
        case .tokenDetails(.delegate(.didFinish)):
            state.path.removeLast()
            return .none
            
        case let .tokenDetails(.delegate(.didRequestNavigateToNewsArticle(article))):
            // Navigate to news article detail from TokenDetails
            state.path.append(.newsArticleDetail(
                NewsArticleDetailCoordinator.State(
                    root: NewsArticleDetailFeature.State(article: article)
                )
            ))
            return .none
            
        case .tokenDetails:
            return .none
            
        case .newsArticleDetail(.delegate(.didFinish)):
            state.path.removeLast()
            return .none
            
        case .newsArticleDetail:
            return .none
            
        case .earn(.delegate(.didFinish)):
            state.path.removeLast()
            return .none
            
        case .earn:
            return .none
        }
    }
    
    // MARK: - Destination
    
    private func reduce(state: inout State, action: Destination.Action) -> Effect<Action> {
        switch action {
        case .walletReceive(.delegate(.didClose)):
            state.destination = nil
            return .none
            
        case .walletReceive:
            return .none
        }
    }
}

