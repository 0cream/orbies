import ComposableArchitecture
import Dependencies
import Foundation

@Reducer
struct PortfolioMainFeature {
    
    @Dependency(\.userService) var userService
    @Dependency(\.hapticFeedbackGenerator) var hapticFeedback
    @Dependency(\.priceHistoryService) var priceHistoryService
    @Dependency(\.portfolioHistoryService) var portfolioHistoryService
    @Dependency(\.searchService) var searchService
    @Dependency(\.newsService) var newsService
    
    // MARK: - Cancel IDs
    
    enum CancelID {
        case balanceRefresh
        case searchDebounce
    }
    
    var body: some Reducer<State, Action> {
        Reduce { state, action in
            switch action {
            case let .view(action):
                return reduce(state: &state, action: action)
                
            case let .reducer(action):
                return reduce(state: &state, action: action)
                
            case .delegate:
                return .none
            }
        }
    }
    
    // MARK: - View Actions
    
    private func reduce(state: inout State, action: Action.View) -> Effect<Action> {
        switch action {
        case .didAppear:
            print("💼 Portfolio: didAppear called")
            return .merge(
                .send(.reducer(.loadBalances)),
                .send(.reducer(.loadAllPortfolioHistory)), // Load all timeframes at once!
                .send(.reducer(.startListeningToUpdates)),
                .send(.reducer(.loadNews))
            )
            
        case let .didSelectTimeframe(timeframe):
            state.selectedTimeframe = timeframe
            
            // Check if we have cached data for this timeframe
            if let cachedHistory = state.portfolioHistoryCache[timeframe] {
                print("📊 Portfolio: Using cached data for \(timeframe) (\(cachedHistory.count) points)")
                return .send(.reducer(.portfolioHistoryLoaded(cachedHistory)))
            } else {
                // Load from backend if not cached
                print("📊 Portfolio: No cache for \(timeframe), loading...")
                return .send(.reducer(.loadPortfolioHistoryForTimeframe(timeframe)))
            }
            
        case .didTapCash:
            return .merge(
                .run { _ in await hapticFeedback.light(intensity: 1.0) },
                .send(.delegate(.didRequestNavigateToCash))
            )
            
        case .didTapInvestments:
            return .merge(
                .run { _ in await hapticFeedback.light(intensity: 1.0) },
                .send(.delegate(.didRequestNavigateToHoldings))
            )
            
        case .didTapEarn:
            return .merge(
                .run { _ in await hapticFeedback.light(intensity: 1.0) },
                .send(.delegate(.didRequestNavigateToEarn))
            )
            
        case .didTapReceive:
            return .merge(
                .run { _ in
                await hapticFeedback.medium(intensity: 1.0)
                },
                .send(.delegate(.didRequestShowReceive))
            )
            
        case let .didTapTokenItem(item):
            return .send(.delegate(.didRequestNavigateToTokenDetails(item: item)))
            
        case let .didTapNewsArticle(article):
            return .send(.delegate(.didRequestNavigateToNewsArticle(article: article)))
            
        case .didReachEndOfNews:
            return .send(.reducer(.loadMoreNews))
            
        case .didTapSearch:
            state.isSearchActive = true
            return .run { _ in
                await hapticFeedback.light(intensity: 1.0)
            }
            
        case .didCancelSearch:
            state.isSearchActive = false
            state.searchQuery = ""
            state.searchResults = []
            return .run { _ in
                await hapticFeedback.light(intensity: 1.0)
            }
            
        case let .didTapSearchResult(result):
            state.isSearchActive = false
            state.searchQuery = ""
            state.searchResults = []
            return .merge(
                .run { _ in
                    await hapticFeedback.light(intensity: 1.0)
                },
                .send(.delegate(.didTapSearchResult(result)))
            )
            
        case let .searchQueryChanged(query):
            state.searchQuery = query
            
            // Clear results if query is too short
            guard query.count >= 2 else {
                state.searchResults = []
                state.isSearching = false
                return .cancel(id: CancelID.searchDebounce)
            }
            
            // Debounce search by 300ms
            state.isSearching = true
            return .run { send in
                try await Task.sleep(for: .milliseconds(300))
                await send(.reducer(.performSearch(query)))
            }
            .cancellable(id: CancelID.searchDebounce, cancelInFlight: true)
            
        case .didTapOrb:
            // TODO: Open Orb AI chat
            return .run { _ in
                await hapticFeedback.medium(intensity: 1.0)
            }
            
        case let .didHighlightChart(value):
            state.highlightedChartValue = value
            return .none
        }
    }
    
    // MARK: - Reducer Actions
    
    private func reduce(state: inout State, action: Action.Reducer) -> Effect<Action> {
        switch action {
        case .loadBalances:
            return .run { [userService] send in
                // Get all balances
                let usdcBalance = await userService.getUsdcBalance()
                let totalBalance = await userService.getTotalBalance()
                let investmentsBalance = Usdc(usdc: totalBalance.USDC - usdcBalance.USDC)
                
                await send(.reducer(.balancesUpdated(
                    cash: usdcBalance,
                    investments: investmentsBalance,
                    total: totalBalance
                )))
                
                // Load real token holdings from UserService
                let tokenHoldingsData = await userService.getTokenHoldings()
                let holdings: [PortfolioTokenItem] = tokenHoldingsData.map { token in
                    PortfolioTokenItem(
                        id: token.address,
                        imageName: token.imageURL ?? "",
                        title: token.name,
                        subtitle: token.symbol,
                        decimals: token.decimals,
                        price: token.price,
                        priceChange: token.priceChange,
                        holdingsAmount: token.balance
                    )
                }
                await send(.reducer(.tokenHoldingsUpdated(holdings)))
            }
            
        case let .balancesUpdated(cash, investments, total):
            state.cashBalance = cash
            state.investmentsBalance = investments
            
            // ✅ Detect balance change direction for animation
            let oldBalance = state.totalBalance.USDC
            let newBalance = total.USDC
            let difference = newBalance - oldBalance
            
            // Use a threshold to avoid floating point precision issues
            if difference > 0.001 {
                state.balanceChangeDirection = .up
                print("💚 Balance UP: $\(String(format: "%.2f", oldBalance)) → $\(String(format: "%.2f", newBalance)) (+$\(String(format: "%.2f", difference)))")
            } else if difference < -0.001 {
                state.balanceChangeDirection = .down
                print("❤️ Balance DOWN: $\(String(format: "%.2f", oldBalance)) → $\(String(format: "%.2f", newBalance)) (-$\(String(format: "%.2f", abs(difference))))")
            } else {
                state.balanceChangeDirection = .none
                // print("⚪️ Balance unchanged: $\(String(format: "%.2f", newBalance))")
            }
            
            state.previousBalance = state.totalBalance
            state.totalBalance = total
            
            // ✅ Update last point in portfolio history (real-time chart update)
            if !state.portfolioHistory.isEmpty {
                let now = Date()
                let currentValue = total.USDC
                
                // Get the timeframe interval
                let intervalSeconds = getTimeframeInterval(state.selectedTimeframe)
                
                // Check if we need to add a new point or update the last one
                if let lastPoint = state.portfolioHistory.last {
                    let timeSinceLastPoint = now.timeIntervalSince(lastPoint.timestamp)
                    
                    if timeSinceLastPoint >= intervalSeconds {
                        // Add new point
                        let newPoint = PricePoint(timestamp: now, price: currentValue)
                        state.portfolioHistory.append(newPoint)
                        // Update cache
                        state.portfolioHistoryCache[state.selectedTimeframe] = state.portfolioHistory
                        print("📊 Added new chart point: $\(String(format: "%.2f", currentValue))")
                    } else {
                        // Update last point
                        state.portfolioHistory[state.portfolioHistory.count - 1] = PricePoint(
                            timestamp: now,
                            price: currentValue
                        )
                        // Update cache
                        state.portfolioHistoryCache[state.selectedTimeframe] = state.portfolioHistory
                    }
                }
            }
            
            // Reset animation after delay
            return .run { send in
                try await Task.sleep(nanoseconds: 800_000_000) // 0.8s (longer to be more visible)
                await send(.reducer(.resetBalanceAnimation))
            }
            
        case .loadPortfolioHistory:
            // Load default timeframe (day)
            return .send(.reducer(.loadPortfolioHistoryForTimeframe(.day)))
            
        case .loadAllPortfolioHistory:
            // Check if we already have cached data
            let hasAllCached = state.portfolioHistoryCache.count == 4
            if hasAllCached {
                print("📊 Portfolio: All timeframes already cached, using cache")
                return .none
            }
            
            guard !state.isLoadingHistory else {
                print("📊 Portfolio: Already loading history, skipping...")
                return .none
            }
            
            state.isLoadingHistory = true
            print("📊 Portfolio: Loading ALL portfolio history (all timeframes)...")
            
            return .run { [portfolioHistoryService, userService] send in
                do {
                    // Fetch all timeframes in one go!
                    let allHistory = try await portfolioHistoryService.getPortfolioHistory()
                    
                    // Convert each timeframe to PricePoint format
                    let dayPoints = allHistory.day.map { dataPoint in
                        PricePoint(
                            timestamp: Date(timeIntervalSince1970: TimeInterval(dataPoint.timestamp) / 1000.0),
                            price: dataPoint.value
                        )
                    }
                    let weekPoints = allHistory.week.map { dataPoint in
                        PricePoint(
                            timestamp: Date(timeIntervalSince1970: TimeInterval(dataPoint.timestamp) / 1000.0),
                            price: dataPoint.value
                        )
                    }
                    let monthPoints = allHistory.month.map { dataPoint in
                        PricePoint(
                            timestamp: Date(timeIntervalSince1970: TimeInterval(dataPoint.timestamp) / 1000.0),
                            price: dataPoint.value
                        )
                    }
                    let yearPoints = allHistory.year.map { dataPoint in
                        PricePoint(
                            timestamp: Date(timeIntervalSince1970: TimeInterval(dataPoint.timestamp) / 1000.0),
                            price: dataPoint.value
                        )
                    }
                    
                    // Downsample each timeframe to optimal chart density
                    let dayDownsampled = downsamplePriceData(dayPoints, for: .day)
                    let weekDownsampled = downsamplePriceData(weekPoints, for: .week)
                    let monthDownsampled = downsamplePriceData(monthPoints, for: .month)
                    let yearDownsampled = downsamplePriceData(yearPoints, for: .year)
                    
                    print("✅ Portfolio: Loaded all portfolio history")
                    print("   Day: \(dayPoints.count) → \(dayDownsampled.count) points")
                    print("   Week: \(weekPoints.count) → \(weekDownsampled.count) points")
                    print("   Month: \(monthPoints.count) → \(monthDownsampled.count) points")
                    print("   Year: \(yearPoints.count) → \(yearDownsampled.count) points")
                    
                    await send(.reducer(.allPortfolioHistoryLoaded(
                        day: dayDownsampled,
                        week: weekDownsampled,
                        month: monthDownsampled,
                        year: yearDownsampled
                    )))
                } catch OrbBackendError.indexingNotComplete(let status, let message) {
                    print("⚠️ Portfolio: Indexing not complete: \(message ?? status)")
                    // Use mock data for all timeframes
                    let totalBalance = await userService.getTotalBalance()
                    let dayMock = generatePortfolioHistoryForTimeframe(timeframe: .day, currentValue: totalBalance.USDC)
                    let weekMock = generatePortfolioHistoryForTimeframe(timeframe: .week, currentValue: totalBalance.USDC)
                    let monthMock = generatePortfolioHistoryForTimeframe(timeframe: .month, currentValue: totalBalance.USDC)
                    let yearMock = generatePortfolioHistoryForTimeframe(timeframe: .year, currentValue: totalBalance.USDC)
                    
                    await send(.reducer(.allPortfolioHistoryLoaded(
                        day: dayMock,
                        week: weekMock,
                        month: monthMock,
                        year: yearMock
                    )))
                } catch {
                    print("❌ Portfolio: Failed to load portfolio history: \(error)")
                    await send(.reducer(.portfolioHistoryLoadFailed(error.localizedDescription)))
                }
            }
            
        case let .loadPortfolioHistoryForTimeframe(timeframe):
            // Prevent duplicate fetches
            guard !state.isLoadingHistory else {
                print("📊 Portfolio: Already loading history, skipping...")
                return .none
            }
            
            state.isLoadingHistory = true
            print("📊 Portfolio: Loading portfolio history for \(timeframe)...")
            return .run { [portfolioHistoryService, userService] send in
                do {
                    // Map ChartTimeframe to PortfolioTimeframe
                    let portfolioTimeframe: PortfolioTimeframe
                    switch timeframe {
                    case .day:
                        portfolioTimeframe = .day
                    case .week:
                        portfolioTimeframe = .week
                    case .month:
                        portfolioTimeframe = .month
                    case .year:
                        portfolioTimeframe = .year
                    }
                    
                    let historyData = try await portfolioHistoryService.getPortfolioHistory(
                        timeframe: portfolioTimeframe
                    )
                    
                    // Convert to PricePoint format for the chart
                    let allPricePoints = historyData.map { dataPoint in
                        PricePoint(
                            timestamp: Date(timeIntervalSince1970: TimeInterval(dataPoint.timestamp) / 1000.0),
                            price: dataPoint.value
                        )
                    }
                    
                    // Downsample to optimal chart density
                    let downsampledPoints = downsamplePriceData(allPricePoints, for: timeframe)
                    
                    print("✅ Portfolio: Loaded \(allPricePoints.count) points, downsampled to \(downsampledPoints.count) for \(timeframe)")
                    await send(.reducer(.portfolioHistoryLoaded(downsampledPoints)))
                } catch OrbBackendError.indexingNotComplete(let status, let message) {
                    print("⚠️ Portfolio: Indexing not complete for \(timeframe): \(message ?? status)")
                    // Use mock data for this timeframe
                    let totalBalance = await userService.getTotalBalance()
                    let mockHistory = generatePortfolioHistoryForTimeframe(
                        timeframe: timeframe,
                        currentValue: totalBalance.USDC
                    )
                    await send(.reducer(.portfolioHistoryLoaded(mockHistory)))
                } catch {
                    print("❌ Portfolio: Failed to load history for \(timeframe): \(error)")
                    await send(.reducer(.portfolioHistoryLoadFailed(error.localizedDescription)))
                }
            }
            
        case let .allPortfolioHistoryLoaded(day, week, month, year):
            state.isLoadingHistory = false
            state.hasLoadedHistory = true
            
            // Cache ALL timeframes
            state.portfolioHistoryCache[.day] = day
            state.portfolioHistoryCache[.week] = week
            state.portfolioHistoryCache[.month] = month
            state.portfolioHistoryCache[.year] = year
            
            print("📦 Portfolio: Cached all timeframes")
            
            // Set the current timeframe's data
            if let currentHistory = state.portfolioHistoryCache[state.selectedTimeframe] {
                state.portfolioHistory = currentHistory
                
                // Calculate change for selected timeframe
                if let first = currentHistory.first, let last = currentHistory.last {
                    let change = ((last.price - first.price) / first.price) * 100
                    state.portfolioChange24h = change
                }
            }
            
            return .none
            
        case let .portfolioHistoryLoaded(history):
            state.isLoadingHistory = false
            state.portfolioHistory = history
            
            // Cache the data for current timeframe
            state.portfolioHistoryCache[state.selectedTimeframe] = history
            
            // Calculate change for selected timeframe
            if let first = history.first, let last = history.last {
                let change = ((last.price - first.price) / first.price) * 100
                state.portfolioChange24h = change
            }
            return .none
            
        case let .portfolioHistoryLoadFailed(error):
            state.isLoadingHistory = false
            print("⚠️ Portfolio: Using mock data due to error: \(error)")
            // Keep using the mock data that was already generated
            return .none
            
        case let .tokenHoldingsUpdated(holdings):
            state.tokenHoldings = holdings
            return .none
            
        case .startListeningToUpdates:
            return .run { send in
                // Refresh balances every 5 seconds to reflect UserService updates
                while true {
                    try? await Task.sleep(for: .seconds(5))
                    await send(.reducer(.recalculateBalance))
                }
            }
            .cancellable(id: CancelID.balanceRefresh)
            
        case .stopListeningToUpdates:
            return .cancel(id: CancelID.balanceRefresh)
            
        case let .tokenUpdateReceived(update):
            // Update matching token in holdings
            if let index = state.tokenHoldings.firstIndex(where: { $0.id == update.tokenId }) {
                var item = state.tokenHoldings[index]
                state.tokenHoldings[index] = PortfolioTokenItem(
                    id: item.id,
                    imageName: item.imageName,
                    title: item.title,
                    subtitle: item.subtitle,
                    decimals: item.decimals,
                    price: update.price,
                    priceChange: update.priceChange,
                    holdingsAmount: item.holdingsAmount
                )
                
                // Recalculate balances
                return .send(.reducer(.recalculateBalance))
            }
            return .none
            
        case .recalculateBalance:
            // print("🔄 Recalculating balance...")
            return .run { [userService] send in
                let usdcBalance = await userService.getUsdcBalance()
                let totalBalance = await userService.getTotalBalance()
                let investmentsBalance = Usdc(usdc: totalBalance.USDC - usdcBalance.USDC)
                
                await send(.reducer(.balancesUpdated(
                    cash: usdcBalance,
                    investments: investmentsBalance,
                    total: totalBalance
                )))
            }
            
        case .resetBalanceAnimation:
            state.balanceChangeDirection = .none
            return .none
            
        case let .performSearch(query):
            return .run { [searchService] send in
                do {
                    let results = try await searchService.searchTokens(query: query)
                    await send(.reducer(.searchResultsLoaded(results)))
                } catch {
                    await send(.reducer(.searchFailed(error.localizedDescription)))
                }
            }
            
        case let .searchResultsLoaded(results):
            state.searchResults = results
            state.isSearching = false
            return .none
            
        case let .searchFailed(error):
            print("❌ Search failed: \(error)")
            state.searchResults = []
            state.isSearching = false
            return .none
            
        case .loadNews:
            return .run { [newsService] send in
                do {
                    let articles = try await newsService.fetchNews()
                    await send(.reducer(.newsLoaded(articles)))
                } catch {
                    print("⚠️ Failed to fetch news from backend, using fallback")
                    // Fallback to local JSON
                    let articles = NewsArticle.loadFromJSON()
                    await send(.reducer(.newsLoaded(articles.isEmpty ? NewsArticle.mockArticles : articles)))
                }
            }
            
        case let .newsLoaded(articles):
            // Store all articles and display first 10
            state.allNewsArticles = articles
            state.displayedArticlesCount = 10
            state.newsArticles = Array(articles.prefix(state.displayedArticlesCount))
            print("✅ Loaded \(articles.count) news articles, displaying \(state.newsArticles.count)")
            return .none
            
        case .loadMoreNews:
            // Load next batch of 10 articles
            let currentCount = state.displayedArticlesCount
            let totalCount = state.allNewsArticles.count
            
            guard currentCount < totalCount else {
                print("📰 No more articles to load")
                return .none
            }
            
            let newCount = min(currentCount + 10, totalCount)
            state.displayedArticlesCount = newCount
            state.newsArticles = Array(state.allNewsArticles.prefix(newCount))
            
            print("📰 Loaded more articles: \(currentCount) → \(newCount)")
            return .none
        }
    }
    
    // MARK: - Private Helpers
    
    /// Get the interval in seconds for each timeframe
    private func getTimeframeInterval(_ timeframe: ChartTimeframe) -> TimeInterval {
        switch timeframe {
        case .day:
            return 15 * 60 // 15 minutes
        case .week:
            return 2 * 60 * 60 // 2 hours
        case .month:
            return 8 * 60 * 60 // 8 hours
        case .year:
            return 4 * 24 * 60 * 60 // 4 days
        }
    }
}

// MARK: - Helpers

// Downsample price data to optimal chart density
private func downsamplePriceData(_ data: [PricePoint], for timeframe: ChartTimeframe) -> [PricePoint] {
    guard !data.isEmpty else { return [] }
    
    let targetInterval: TimeInterval
    switch timeframe {
    case .day:
        targetInterval = 900 // 15 minutes → ~96 points
    case .week:
        targetInterval = 7200 // 2 hours → ~84 points
    case .month:
        targetInterval = 28800 // 8 hours → ~90 points
    case .year:
        targetInterval = 345600 // 4 days → ~91 points
    }
    
    var downsampled: [PricePoint] = []
    var lastTimestamp: Date?
    
    for point in data {
        if let last = lastTimestamp {
            if point.timestamp.timeIntervalSince(last) >= targetInterval {
                downsampled.append(point)
                lastTimestamp = point.timestamp
            }
        } else {
            // Always include first point
            downsampled.append(point)
            lastTimestamp = point.timestamp
        }
    }
    
    // Always include last point if not already included
    if let lastPoint = data.last, downsampled.last?.timestamp != lastPoint.timestamp {
        downsampled.append(lastPoint)
    }
    
    return downsampled
}

// Generate mock portfolio history for a specific timeframe
private func generatePortfolioHistoryForTimeframe(timeframe: ChartTimeframe, currentValue: Double) -> [PricePoint] {
    var history: [PricePoint] = []
    let now = Date()
    
    // Configure time range and data points based on timeframe
    let (startTime, interval, pointCount): (Date, TimeInterval, Int)
    
    switch timeframe {
    case .day:
        // 1 day = 24 hours, every 15 minutes = 96 points
        startTime = now.addingTimeInterval(-86400)
        interval = 900  // 15 minutes
        pointCount = 96
        
    case .week:
        // 1 week = 7 days, every 2 hours = 84 points
        startTime = now.addingTimeInterval(-604800)
        interval = 7200  // 2 hours
        pointCount = 84
        
    case .month:
        // 1 month = 30 days, every 8 hours = 90 points
        startTime = now.addingTimeInterval(-2592000)
        interval = 28800  // 8 hours
        pointCount = 90
        
    case .year:
        // 1 year = 365 days, every 4 days = 91 points
        startTime = now.addingTimeInterval(-31536000)
        interval = 345600  // 4 days
        pointCount = 91
    }
    
    // Start with a value slightly different from current (±30%)
    var value = currentValue * Double.random(in: 0.7...1.3)
    
    // Generate points with realistic volatility
    var currentTime = startTime
    for i in 0..<pointCount {
        let progress = Double(i) / Double(pointCount)
        
        // Add random walk with trend toward current value
        let volatility = 0.02 * (1.0 - progress * 0.5)  // Less volatile as we approach now
        let randomChange = Double.random(in: -volatility...volatility)
        value = value * (1.0 + randomChange)
        
        // Gradually converge to current value
        let convergenceFactor = pow(progress, 2) * 0.1  // Stronger convergence near the end
        value = value * (1.0 - convergenceFactor) + currentValue * convergenceFactor
        
        // Keep within reasonable bounds (50% to 150% of current)
        value = max(currentValue * 0.5, min(currentValue * 1.5, value))
        
        history.append(PricePoint(timestamp: currentTime, price: value))
        currentTime = currentTime.addingTimeInterval(interval)
    }
    
    // Ensure last point is exactly current value at current time
    if let lastPoint = history.last {
        if lastPoint.timestamp < now {
            history.append(PricePoint(timestamp: now, price: currentValue))
        } else {
            history[history.count - 1] = PricePoint(timestamp: now, price: currentValue)
        }
    }
    
    return history
}

// Legacy function - kept for backward compatibility but now uses new implementation
private func generatePortfolioHistory(currentValue: Double) -> [PricePoint] {
    return generatePortfolioHistoryForTimeframe(timeframe: .day, currentValue: currentValue)
}

