import ComposableArchitecture
import SFSafeSymbols
import SwiftUI

@ViewAction(for: PortfolioMainFeature.self)
struct PortfolioMainView: View {

    let store: StoreOf<PortfolioMainFeature>
    @FocusState private var isSearchFieldFocused: Bool
    @State private var glowOffset1: CGFloat = 0
    @State private var glowOffset2: CGFloat = 0
    @State private var glowOffset3: CGFloat = 0
    
    private func dismissKeyboard() {
        isSearchFieldFocused = false
        // Force immediate keyboard dismissal
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }

    var body: some View {
        ZStack {
            // Dark background with animated orange glows
            ZStack {
                Color.black
                    .ignoresSafeArea()
                
                // Animated blurred orange gradient dots
                GeometryReader { geometry in
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [
                                    Color(red: 1.0, green: 0.3, blue: 0.2).opacity(0.15),
                                    Color(red: 1.0, green: 0.3, blue: 0.2).opacity(0.08),
                                    Color.clear
                                ],
                                center: .center,
                                startRadius: 50,
                                endRadius: 200
                            )
                        )
                        .frame(width: 400, height: 400)
                        .blur(radius: 40)
                        .position(x: geometry.size.width * 0.2 + glowOffset1, y: geometry.size.height * 0.6)
                    
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [
                                    Color(red: 1.0, green: 0.3, blue: 0.2).opacity(0.15),
                                    Color(red: 1.0, green: 0.3, blue: 0.2).opacity(0.08),
                                    Color.clear
                                ],
                                center: .center,
                                startRadius: 50,
                                endRadius: 200
                            )
                        )
                        .frame(width: 400, height: 400)
                        .blur(radius: 40)
                        .position(x: geometry.size.width * 0.8 + glowOffset2, y: geometry.size.height * 0.75)
                    
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [
                                    Color(red: 1.0, green: 0.3, blue: 0.2).opacity(0.15),
                                    Color(red: 1.0, green: 0.3, blue: 0.2).opacity(0.08),
                                    Color.clear
                                ],
                                center: .center,
                                startRadius: 50,
                                endRadius: 200
                            )
                        )
                        .frame(width: 400, height: 400)
                        .blur(radius: 40)
                        .position(x: geometry.size.width * 0.5 + glowOffset3, y: geometry.size.height * 0.85)
                }
            }
            
            ScrollView(.vertical) {
                VStack(spacing: 0) {
                    // Header with title and search button
                    HStack {
                        if !store.isSearchActive {
                            HStack(spacing: 8) {
                                Image("orb_small_orange")
                                    .resizable()
                                    .frame(width: 28, height: 28)

                                Text("Invest")
                                    .font(.system(size: 28, weight: .bold))
                                    .foregroundStyle(.white)
                            }
                            .transition(
                                .opacity.combined(with: .scale(scale: 0.9))
                            )
                        }

                        Spacer()

                        if !store.isSearchActive {
                            Button {
                                send(.didTapSearch)
                            } label: {
                                Image(systemSymbol: .magnifyingglass)
                                    .font(.system(size: 20, weight: .medium))
                                    .foregroundStyle(.white.opacity(0.9))
                                    .frame(width: 44, height: 44)
                            }
                            .transition(
                                .opacity.combined(with: .scale(scale: 0.9))
                            )
                        }
                    }
                    .padding(.horizontal, 24)
                    .padding(.top, 16)
                    .padding(.bottom, 24)
                    .animation(
                        .spring(response: 0.3, dampingFraction: 0.8),
                        value: store.isSearchActive
                    )

                    // Total Balance section
                    VStack(alignment: .leading, spacing: 8) {
                        HStack(spacing: 6) {
                            Text("Total Balance")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundStyle(.white.opacity(0.6))

                            // Change indicator (only show if value is valid and not zero)
                            if !store.portfolioChange24h.isNaN && !store.portfolioChange24h.isInfinite && store.portfolioChange24h != 0 {
                                HStack(spacing: 2) {
                                    Image(
                                        systemSymbol: store.portfolioChange24h
                                            >= 0 ? .arrowUp : .arrowDown
                                    )
                                    .font(.system(size: 10, weight: .bold))
                                    Text(store.portfolioChange24hFormatted)
                                        .font(
                                            .system(size: 12, weight: .semibold)
                                        )
                                }
                                .foregroundStyle(
                                    store.portfolioChange24h >= 0
                                        ? .tokens.green : .tokens.red
                                )
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(
                                    (store.portfolioChange24h >= 0
                                        ? Color.tokens.green : Color.tokens.red)
                                        .opacity(0.1),
                                    in: .capsule
                                )
                            }

                            Spacer()

                            // Show date when chart is being touched
                            if let date = store.displayedDate {
                                Text(date)
                                    .font(.system(size: 13, weight: .regular))
                                    .foregroundStyle(.white.opacity(0.6))
                                    .transition(
                                        .opacity.combined(
                                            with: .scale(scale: 0.95)
                                        )
                                    )
                            }
                        }
                        .animation(
                            .easeInOut(duration: 0.2),
                            value: store.displayedDate
                        )

                        Text(store.displayedBalanceFormatted)
                            .font(.system(size: 48, weight: .bold))
                            .foregroundStyle(
                                store.balanceChangeDirection == .up
                                    ? Color.tokens.green
                                    : store.balanceChangeDirection == .down
                                        ? Color.tokens.red
                                        : Color.white
                            )
                            .contentTransition(.numericText())
                            .animation(
                                .easeInOut(duration: 0.3),
                                value: store.balanceChangeDirection
                            )
                            .animation(.default, value: store.displayedBalance)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 24)
                    .padding(.bottom, 20)

                    // Mini chart
                    if store.isLoadingHistory && !store.hasLoadedHistory {
                        // Loading shimmer for chart
                        VStack(alignment: .leading, spacing: 12) {
                            // Chart shimmer
                            RoundedRectangle(cornerRadius: 8)
                                .fill(Color.white.opacity(0.05))
                                .frame(height: 120)
                                .shimmer()

                            // Timeframe selector shimmer
                            HStack(spacing: 16) {
                                ForEach(0..<4, id: \.self) { _ in
                                    RoundedRectangle(cornerRadius: 6)
                                        .fill(Color.white.opacity(0.05))
                                        .frame(width: 40, height: 24)
                                }
                            }
                            .shimmer()
                        }
                        .padding(.horizontal, 24)
                        .padding(.bottom, 24)

                    } else if !store.chartData.isEmpty {
                        OptimizedChart(
                            dataProvider: store.chartDataProvider,
                            accentColor: store.portfolioChange24h >= 0
                                ? .tokens.green : .tokens.red,
                            numberOfLabels: 0,
                            axisLabel: { _ in EmptyView() },
                            useSmoothedSelection: true,
                            onHighlightChange: { value in
                                send(.didHighlightChart(value))
                            }
                        )
                        .frame(height: 120)
                        .padding(.horizontal, 24)
                        .padding(.bottom, 8)

                        // News article timeline (if any relevant articles)
                        if !store.relevantArticlesForChart.isEmpty {
                            NewsTimelineView(
                                articles: store.relevantArticlesForChart,
                                chartData: store.chartData,
                                onArticleTap: { article in
                                    send(.didTapNewsArticle(article))
                                }
                            )
                            .padding(.horizontal, 24)
                            .padding(.bottom, 12)
                        }

                        // Timeframe selector
                        HStack(spacing: 16) {
                            ForEach(ChartTimeframe.allCases, id: \.self) {
                                timeframe in
                                Button {
                                    send(.didSelectTimeframe(timeframe))
                                } label: {
                                    Text(timeframe.rawValue)
                                        .font(
                                            .system(
                                                size: 12,
                                                weight: store.selectedTimeframe
                                                    == timeframe
                                                    ? .semibold : .medium
                                            )
                                        )
                                        .foregroundStyle(
                                            store.selectedTimeframe == timeframe
                                                ? .white
                                                : .white.opacity(0.5)
                                        )
                                }
                            }
                        }
                        .padding(.horizontal, 24)
                        .padding(.bottom, 24)
                    }

                    // Action grid (2x2)
                    LazyVGrid(
                        columns: [
                            GridItem(.flexible()), GridItem(.flexible()),
                        ],
                        spacing: 16
                    ) {
                        // Cash button
                        PortfolioActionCard(
                            icon: Image(systemSymbol: .dollarsignCircleFill),
                            iconColor: .blue,
                            title: "Cash",
                            subtitle: store.cashBalanceFormatted
                        ) {
                            send(.didTapCash)
                        }

                        // Holdings button
                        PortfolioActionCard(
                            icon: Image(systemSymbol: .chartLineUptrendXyaxis),
                            iconColor: .orange,
                            title: "Holdings",
                            subtitle: store.investmentsBalanceFormatted
                        ) {
                            send(.didTapInvestments)
                        }

                        // Earn button
                        PortfolioActionCard(
                            icon: Image(systemSymbol: .percent),
                            iconColor: .purple,
                            title: "Earn",
                            subtitle: "Up to 6.68% APY"
                        ) {
                            send(.didTapEarn)
                        }

                        // Receive button (+ icon)
                        Button {
                            send(.didTapReceive)
                        } label: {
                            ZStack {
                                RoundedRectangle(cornerRadius: 16)
                                    .fill(Color.white.opacity(0.08))

                                Image(systemSymbol: .plus)
                                    .font(.system(size: 32, weight: .medium))
                                    .foregroundStyle(.white)
                            }
                        }
                        .buttonStyle(.responsive(.default))
                    }
                    .padding(.horizontal, 24)
                    .padding(.bottom, 32)

                    // News section
                    VStack(alignment: .leading, spacing: 16) {
                        Text("News")
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundStyle(.white)
                            .padding(.horizontal, 24)

                        LazyVStack(spacing: 20) {
                            ForEach(store.newsArticles) { article in
                                Button {
                                    send(.didTapNewsArticle(article))
                                } label: {
                                    CompactNewsCard(article: article)
                                        .padding(.horizontal, 24)
                                }
                                .buttonStyle(.plain)
                            }
                            
                            // Pagination trigger - appears when scrolling to end
                            if store.newsArticles.count < store.allNewsArticles.count {
                                Color.clear
                                    .frame(height: 1)
                                    .onAppear {
                                        send(.didReachEndOfNews)
                                    }
                            }
                        }
                        .padding(.bottom, 120) // Space for tab bar
                    }

                    Spacer()
                }
            }
            .scrollIndicators(.hidden)
            .blur(radius: store.isSearchActive ? 8 : 0)
            .animation(.easeInOut(duration: 0.25), value: store.isSearchActive)
            .onAppear {
                send(.didAppear)
                startGlowAnimation()
            }
            .onDisappear {
                store.send(.reducer(.stopListeningToUpdates))
            }

            // Search overlay
            if store.isSearchActive {
                Color.black.opacity(0.3)
                    .ignoresSafeArea()
                    .transition(.opacity)
                    .onTapGesture {
                        dismissKeyboard()
                        send(.didCancelSearch)
                    }

                VStack {
                    // Search bar
                    HStack(spacing: 12) {
                        Image(systemSymbol: .magnifyingglass)
                            .font(.system(size: 18, weight: .medium))
                            .foregroundStyle(.white.opacity(0.6))

                        TextField(
                            "Search tokens...",
                            text: Binding(
                                get: { store.searchQuery },
                                set: { send(.searchQueryChanged($0)) }
                            )
                        )
                        .font(.system(size: 17, weight: .regular))
                        .foregroundStyle(.white)
                        .focused($isSearchFieldFocused)
                        .onSubmit {
                            // Handle search submit if needed
                        }
                        .onAppear {
                            // Focus immediately when the text field appears
                            isSearchFieldFocused = true
                        }

                        if !store.searchQuery.isEmpty {
                            Button {
                                send(.searchQueryChanged(""))
                            } label: {
                                Image(systemSymbol: .xmarkCircleFill)
                                    .font(.system(size: 18, weight: .medium))
                                    .foregroundStyle(.white.opacity(0.6))
                            }
                            .transition(.scale.combined(with: .opacity))
                        }

                        Button {
                            dismissKeyboard()
                            send(.didCancelSearch)
                        } label: {
                            Image(systemSymbol: .xmarkCircleFill)
                                .font(.system(size: 24, weight: .medium))
                                .foregroundStyle(.white.opacity(0.6))
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.white.opacity(0.12))
                            .shadow(
                                color: .black.opacity(0.3),
                                radius: 8,
                                x: 0,
                                y: 2
                            )
                    )
                    .padding(.horizontal, 16)
                    .padding(.top, 16)
                    
                    // Search results
                    if store.isSearching {
                        VStack {
                            ProgressView()
                                .tint(.white)
                                .padding(.top, 40)
                            Spacer()
                        }
                    } else if !store.searchResults.isEmpty {
                        ScrollView {
                            LazyVStack(spacing: 0) {
                                ForEach(store.searchResults) { result in
                                SearchResultRow(result: result)
                                    .contentShape(Rectangle())
                                    .onTapGesture {
                                        send(.didTapSearchResult(result))
                                    }
                                }
                            }
                            .padding(.top, 8)
                        }
                    } else if !store.searchQuery.isEmpty {
                        VStack {
                            Text("No results found")
                                .font(.system(size: 15, weight: .regular))
                                .foregroundStyle(.white.opacity(0.5))
                                .padding(.top, 40)
                            Spacer()
                        }
                    } else {
                        Spacer()
                    }
                }
                .transition(.move(edge: .top).combined(with: .opacity))
                .onChange(of: store.isSearchActive) { oldValue, newValue in
                    if newValue {
                        // Add a small delay to ensure the view is visible before focusing
                        Task { @MainActor in
                            try? await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds
                            isSearchFieldFocused = true
                        }
                    } else {
                        // Immediately dismiss keyboard when hiding search
                        dismissKeyboard()
                    }
                }
            }
        }
        .animation(
            .spring(response: 0.35, dampingFraction: 0.85),
            value: store.isSearchActive
        )
    }
    
    private func startGlowAnimation() {
        // Slow flowing movement for gradient dots (slightly lower in the view for news section)
        withAnimation(.easeInOut(duration: 8).repeatForever(autoreverses: true)) {
            glowOffset1 = 100
        }
        withAnimation(.easeInOut(duration: 10).repeatForever(autoreverses: true)) {
            glowOffset2 = -80
        }
        withAnimation(.easeInOut(duration: 9).repeatForever(autoreverses: true)) {
            glowOffset3 = 120
        }
    }
}

// MARK: - Portfolio Action Card

struct PortfolioActionCard: View {
    let icon: Image
    let iconColor: Color
    let title: String
    let subtitle: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 8) {
                ZStack {
                    Circle()
                        .fill(iconColor.opacity(0.15))
                        .frame(width: 44, height: 44)

                    icon
                        .font(.system(size: 18, weight: .regular))
                        .foregroundStyle(iconColor)
                        .frame(width: 44, height: 44)
                }

                Spacer()

                Text(title)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(.white.opacity(0.6))
                    .frame(maxWidth: .infinity, alignment: .leading)

                Text(subtitle)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .contentTransition(.numericText())
            }
            .padding(16)
            .frame(height: 140)
            .background(
                Color.white.opacity(0.08),
                in: RoundedRectangle(cornerRadius: 16)
            )
        }
        .buttonStyle(.responsive(.default))
    }
}

// MARK: - Portfolio Token Row

struct PortfolioTokenRow: View {
    let item: PortfolioTokenItem

    var body: some View {
        HStack(spacing: 12) {
            // Token image
            TokenImageView(
                iconURL: item.imageName,
                fallbackText: String(item.title.prefix(1)),
                size: 44
            )

            // Token info
            VStack(alignment: .leading, spacing: 2) {
                Text(item.title)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundStyle(.white)

                Text(item.subtitle)
                    .font(.system(size: 14, weight: .regular))
                    .foregroundStyle(.white.opacity(0.6))
            }

            Spacer()

            // Value info
            VStack(alignment: .trailing, spacing: 2) {
                Text(item.formattedValue)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(.white)
                    .contentTransition(.numericText())

                Text(item.formattedAmount)
                    .font(.system(size: 12, weight: .regular))
                    .foregroundStyle(.white.opacity(0.6))
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(Color.white.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

// MARK: - Compact News Card

struct CompactNewsCard: View {
    let article: NewsArticle
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Date
            Text(formattedDate)
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(.white.opacity(0.6))
            
            // Title
            Text(article.title)
                .font(.system(size: 18, weight: .bold))
                .foregroundStyle(.white)
                .multilineTextAlignment(.leading)
                .lineLimit(3)
            
            // Subtitle
            Text(article.subtitle)
                .font(.system(size: 13, weight: .regular))
                .foregroundStyle(.white.opacity(0.85))
                .multilineTextAlignment(.leading)
                .lineLimit(2)
            
            // Token pills
            if !article.tokens.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(article.tokens) { token in
                            HStack(spacing: 6) {
                                TokenImageView(
                                    iconURL: token.imageUrl,
                                    fallbackText: token.symbol,
                                    size: 14,
                                    tokenMint: token.id
                                )
                                
                                Text(token.symbol)
                                    .font(.system(size: 11, weight: .semibold))
                                    .foregroundStyle(.white)
                            }
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.white.opacity(0.15))
                            .clipShape(Capsule())
                        }
                    }
                }
            }
        }
        .padding(16)
        .background(
            ZStack {
                // Blur layer
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.white.opacity(0.05))
                    .blur(radius: 10)
                
                // Main background
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.white.opacity(0.15))
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(Color.white.opacity(0.25), lineWidth: 1)
                    )
            }
        )
        .shadow(color: Color.black.opacity(0.4), radius: 15, x: 0, y: 5)
    }
    
    private var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d, yyyy"
        return formatter.string(from: article.publishedAt)
    }
}

// MARK: - Search Result Row

struct SearchResultRow: View {
    let result: SearchTokenResult
    
    var body: some View {
        HStack(spacing: 12) {
            // Token image
            TokenImageView(
                iconURL: result.logoURI,
                fallbackText: result.symbol ?? "?",
                size: 40
            )
            
            // Token info
            VStack(alignment: .leading, spacing: 4) {
                Text(result.symbol ?? "Unknown")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(.white)
                
                Text(result.name ?? result.address)
                    .font(.system(size: 13, weight: .regular))
                    .foregroundStyle(.white.opacity(0.6))
                    .lineLimit(1)
            }
            
            Spacer()
            
            // Price
            if let price = result.lastPrice {
                Text("$\(String(format: "%.4f", price.price))")
                    .font(.system(size: 15, weight: .medium))
                    .foregroundStyle(.white)
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
        .background(Color.clear)
    }
}
