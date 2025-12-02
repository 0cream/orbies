import ComposableArchitecture

extension TokenDetailsFeature {
    @CasePathable
    enum Action: ViewAction {
        enum View {
            case didAppear
            case didTapBack
            case didTapCopyTicker
            case didSelectTimeframe(ChartTimeframe)
            case didHighlightChart(LineChartValue?)
            case didTapSell
            case didTapBuy
            case didTapContactNick
            case didTapShareApp
            case didTapNewsArticle(NewsArticle)
        }
        
        enum Reducer {
            case loadPriceHistory
            case priceHistoryLoaded([PricePoint])
            case fetchUserBalance
            case userBalanceUpdated(tokensCount: Double, tokensValue: Double)
            case tokenBalanceStreamUpdate(Token)
            case showActivityPopup(text: String, emoji: String, isSuccess: Bool)
            case hideActivityPopup
            case loadNews
            case newsLoaded([NewsArticle])
        }
        
        enum Delegate {
            case didFinish
            case didRequestBuyToken(tokenName: String, tokenTicker: String, tokenMintAddress: String, tokenDecimals: Int, currentPrice: Double, venue: TradingVenue)
            case didRequestSellToken(tokenName: String, tokenTicker: String, tokenMintAddress: String, tokenDecimals: Int, currentPrice: Double, venue: TradingVenue, userTokensBalance: Double)
            case didRequestNavigateToNewsArticle(article: NewsArticle)
        }
        
        case view(View)
        case reducer(Reducer)
        case delegate(Delegate)
    }
} 