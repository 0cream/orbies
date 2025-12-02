import ComposableArchitecture

extension PortfolioMainFeature {
    @CasePathable
    enum Action: ViewAction {
        enum View {
            case didAppear
            case didSelectTimeframe(ChartTimeframe)
            case didTapCash
            case didTapInvestments
            case didTapEarn
            case didTapReceive
            case didTapTokenItem(PortfolioTokenItem)
            case didTapNewsArticle(NewsArticle)
            case didReachEndOfNews
            case didTapSearch
            case didCancelSearch
            case searchQueryChanged(String)
            case didTapSearchResult(SearchTokenResult)
            case didTapOrb
            case didHighlightChart(LineChartValue?)
        }
        
        enum Reducer {
            case loadBalances
            case balancesUpdated(cash: Usdc, investments: Usdc, total: Usdc)
            case loadPortfolioHistory // NEW: Load real portfolio history from backend
            case loadAllPortfolioHistory // Load all timeframes at once (optimal!)
            case loadPortfolioHistoryForTimeframe(ChartTimeframe) // Load history for specific timeframe
            case portfolioHistoryLoaded([PricePoint])
            case allPortfolioHistoryLoaded(day: [PricePoint], week: [PricePoint], month: [PricePoint], year: [PricePoint])
            case portfolioHistoryLoadFailed(String) // NEW: Handle loading errors
            case tokenHoldingsUpdated([PortfolioTokenItem])
            case loadNews
            case newsLoaded([NewsArticle])
            case loadMoreNews
            case performSearch(String)
            case searchResultsLoaded([SearchTokenResult])
            case searchFailed(String)
            case startListeningToUpdates
            case stopListeningToUpdates
            case tokenUpdateReceived(TokenUpdate)
            case recalculateBalance
            case resetBalanceAnimation
        }
        
        enum Delegate {
            case didRequestNavigateToCash
            case didRequestNavigateToHoldings
            case didRequestNavigateToEarn
            case didRequestNavigateToTokenDetails(item: PortfolioTokenItem)
            case didRequestNavigateToNewsArticle(article: NewsArticle)
            case didRequestShowReceive
            case didTapSearchResult(SearchTokenResult)
        }
        
        case view(View)
        case reducer(Reducer)
        case delegate(Delegate)
    }
}

