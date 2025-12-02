import SwiftUI
import ComposableArchitecture
import SFSafeSymbols

@ViewAction(for: OnboardingFeature.self)
struct OnboardingView: View {
    
    let store: StoreOf<OnboardingFeature>
    
    private var buttonText: String {
        switch store.currentPage {
        case 0, 1:
            return "Next"
        case 2:
            return "Sign up"
        default:
            return "Get Started"
        }
    }
    
    private var firstLineText: String {
        switch store.currentPage {
        case 0:
            return "Invest."
        case 1:
            return "Be ahead."
        case 2:
            return "Access."
        default:
            return "Invest."
        }
    }
    
    private var secondLineText: String {
        switch store.currentPage {
        case 0:
            return "with Taste."
        case 1:
            return "Of everyone else."
        case 2:
            return "All world's markets."
        default:
            return "with Taste."
        }
    }
    
    var body: some View {
        ZStack {
            Color.black
                .ignoresSafeArea()
            
            // Gradient at top 25%
            VStack(spacing: 0) {
                LinearGradient(
                    colors: [
                        Color.white.opacity(0.1),
                        Color.black
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .frame(height: UIScreen.main.bounds.height * 0.5)
                
                Spacer()
            }
            .ignoresSafeArea()
            .allowsHitTesting(false)
        }
        .overlay(
            VStack(spacing: 0) {
                // Page-specific content area
                Group {
                    switch store.currentPage {
                    case 0:
                        OnboardingPage1()
                    case 1:
                        OnboardingPage2(
                            showOrbLogo: store.showOrbLogo,
                            orbLogoScaled: store.orbLogoScaled,
                            showNotification1: store.showNotification1,
                            showNotification2: store.showNotification2,
                            showNotification3: store.showNotification3,
                            showNotification4: store.showNotification4,
                            showNotification5: store.showNotification5,
                            showNotification6: store.showNotification6,
                            showNotification7: store.showNotification7,
                            showNotification8: store.showNotification8,
                            showNotification9: store.showNotification9,
                            showNotification10: store.showNotification10
                        )
                    case 2:
                        OnboardingPage3()
                    default:
                        EmptyView()
                    }
                }
                .opacity(store.showPageContent ? 1 : 0)
                .animation(.easeOut(duration: 0.3), value: store.showPageContent)
                
                Spacer()
                
                // Fixed across all pages: Text (animated, changes per page)
                VStack(alignment: .leading, spacing: -4) {
                    Text(firstLineText)
                        .font(.system(size: 52, weight: .medium))
                        .foregroundColor(.white)
                        .opacity(store.showFirstLine ? 1 : 0)
                        .animation(.easeOut(duration: 0.3), value: store.showFirstLine)
                    
                    Text(secondLineText)
                        .font(.system(size: 52, weight: .medium))
                        .foregroundColor(.white)
                        .opacity(store.showSecondLine ? 1 : 0)
                        .animation(.easeOut(duration: 0.3), value: store.showSecondLine)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 24)
                .padding(.bottom, 40)
                
                // Fixed across all pages: Button
                Button {
                    if store.textAnimationCompleted {
                        send(.didTapNext)
                    }
                } label: {
                    Text(buttonText)
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 56)
                        .background(Color(red: 1.0, green: 0.3, blue: 0.2))
                        .cornerRadius(28)
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 32)
                .buttonStyle(.responsive(.default))
            }
                .ignoresSafeArea()
        )
        .statusBar(hidden: true)
        .onAppear {
            send(.didAppear)
        }
    }
    
}

// MARK: - Onboarding Page 1

struct OnboardingPage1: View {
    var body: some View {
        VStack(spacing: 0) {
            Spacer()
            
            // Benjamin Franklin eyes image
            Image("benjamin_franklin")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(maxWidth: .infinity)
            
            Spacer()
        }
    }
}

// MARK: - Onboarding Page 2

struct OnboardingPage2: View {
    let showOrbLogo: Bool
    let orbLogoScaled: Bool
    let showNotification1: Bool
    let showNotification2: Bool
    let showNotification3: Bool
    let showNotification4: Bool
    let showNotification5: Bool
    let showNotification6: Bool
    let showNotification7: Bool
    let showNotification8: Bool
    let showNotification9: Bool
    let showNotification10: Bool
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Center Orb logo with glow
                if showOrbLogo {
                    PulsatingOrbView(orbLogoScaled: orbLogoScaled)
                        .position(x: geometry.size.width / 2, y: geometry.size.height / 2)
                }
                
                // Notification 1: Close to center - upper left (random)
                if showNotification1 {
                    NotificationCard(
                        title: "Avici ico just started",
                        subtitle: "new financial app with debit cards",
                        buttonText: "Deploy capital"
                    )
                    .position(x: geometry.size.width * 0.28, y: geometry.size.height * 0.38)
                    .scaleEffect(showNotification1 ? 1 : 0.3)
                    .opacity(showNotification1 ? 1 : 0)
                    .animation(.spring(response: 0.5, dampingFraction: 0.3, blendDuration: 0), value: showNotification1)
                }
                
                // Notification 2: Close to center - right (random)
                if showNotification2 {
                    NotificationCard(
                        title: "SOLOMON offering",
                        subtitle: "up to 12% APY on staked cash",
                        buttonText: "Add cash"
                    )
                    .position(x: geometry.size.width * 0.64, y: geometry.size.height * 0.32)
                    .scaleEffect(showNotification2 ? 1 : 0.3)
                    .opacity(showNotification2 ? 1 : 0)
                    .animation(.spring(response: 0.5, dampingFraction: 0.3, blendDuration: 0), value: showNotification2)
                }
                
                // Notification 3: Close to center - lower (random)
                if showNotification3 {
                    NotificationCard(
                        title: "NVDA potential price drop",
                        subtitle: "Meta moving from Nvidia to Google chips for AI",
                        buttonText: "Short NVDA"
                    )
                    .position(x: geometry.size.width * 0.30, y: geometry.size.height * 0.58)
                    .scaleEffect(showNotification3 ? 1 : 0.3)
                    .opacity(showNotification3 ? 1 : 0)
                    .animation(.spring(response: 0.5, dampingFraction: 0.3, blendDuration: 0), value: showNotification3)
                }
                
                // Notification 4: Right side
                if showNotification4 {
                    NotificationCard(
                        title: "80% chance (Polymarket)",
                        subtitle: "of conflict in Middle East",
                        buttonText: "Hedge risk"
                    )
                    .position(x: geometry.size.width * 0.82, y: geometry.size.height * 0.65)
                    .scaleEffect(showNotification4 ? 1 : 0.3)
                    .opacity(showNotification4 ? 1 : 0)
                    .animation(.spring(response: 0.5, dampingFraction: 0.3, blendDuration: 0), value: showNotification4)
                }
                
                // Notification 5: Center right
                if showNotification5 {
                    NotificationCard(
                        title: "BTC ETF approval imminent",
                        subtitle: "SEC decision expected this week",
                        buttonText: "Buy BTC"
                    )
                    .position(x: geometry.size.width * 0.70, y: geometry.size.height * 0.48)
                    .scaleEffect(showNotification5 ? 1 : 0.3)
                    .opacity(showNotification5 ? 1 : 0)
                    .animation(.spring(response: 0.5, dampingFraction: 0.3, blendDuration: 0), value: showNotification5)
                }
                
                // Notification 6: Medium distance - top right
                if showNotification6 {
                    NotificationCard(
                        title: "SOL ecosystem growth",
                        subtitle: "Total value locked up 47% this month",
                        buttonText: "Explore SOL"
                    )
                    .position(x: geometry.size.width * 0.75, y: geometry.size.height * 0.15)
                    .scaleEffect(showNotification6 ? 1 : 0.3)
                    .opacity(showNotification6 ? 1 : 0)
                    .animation(.spring(response: 0.5, dampingFraction: 0.3, blendDuration: 0), value: showNotification6)
                }
                
                // Notification 7: Left bottom area
                if showNotification7 {
                    NotificationCard(
                        title: "Gold hits all-time high",
                        subtitle: "Inflation concerns drive precious metals rally",
                        buttonText: "Hedge portfolio"
                    )
                    .position(x: geometry.size.width * 0.22, y: geometry.size.height * 0.72)
                    .scaleEffect(showNotification7 ? 1 : 0.3)
                    .opacity(showNotification7 ? 1 : 0)
                    .animation(.spring(response: 0.5, dampingFraction: 0.3, blendDuration: 0), value: showNotification7)
                }
                
                // Notification 8: Far from center - top far left
                if showNotification8 {
                    NotificationCard(
                        title: "Tesla earnings beat",
                        subtitle: "Q4 deliveries exceed expectations by 15%",
                        buttonText: "Long TSLA"
                    )
                    .position(x: geometry.size.width * 0.25, y: geometry.size.height * 0.19)
                    .scaleEffect(showNotification8 ? 1 : 0.3)
                    .opacity(showNotification8 ? 1 : 0)
                    .animation(.spring(response: 0.5, dampingFraction: 0.3, blendDuration: 0), value: showNotification8)
                }
                
                // Notification 9: Bottom center-left
                if showNotification9 {
                    NotificationCard(
                        title: "OpenAI launches GPT-5",
                        subtitle: "Major AI breakthrough announced",
                        buttonText: "AI Stocks"
                    )
                    .position(x: geometry.size.width * 0.35, y: geometry.size.height * 0.82)
                    .scaleEffect(showNotification9 ? 1 : 0.3)
                    .opacity(showNotification9 ? 1 : 0)
                    .animation(.spring(response: 0.5, dampingFraction: 0.3, blendDuration: 0), value: showNotification9)
                }
                
                // Notification 10: Right bottom
                if showNotification10 {
                    NotificationCard(
                        title: "Fed hints at rate cuts",
                        subtitle: "Powell suggests easing cycle in Q2 2025",
                        buttonText: "Rebalance"
                    )
                    .position(x: geometry.size.width * 0.78, y: geometry.size.height * 0.79)
                    .scaleEffect(showNotification10 ? 1 : 0.3)
                    .opacity(showNotification10 ? 1 : 0)
                    .animation(.spring(response: 0.5, dampingFraction: 0.3, blendDuration: 0), value: showNotification10)
                }
            }
        }
    }
}

// MARK: - Onboarding Page 3

struct OnboardingPage3: View {
    @State private var offsetRow1: CGFloat = -3600  // Start left, animate right
    @State private var offsetRow2: CGFloat = 0
    @State private var offsetRow3: CGFloat = -3600  // Start left, animate right
    @State private var offsetRow4: CGFloat = 0
    @State private var offsetRow5: CGFloat = -3600  // Start left, animate right
    @State private var glowOffset1: CGFloat = 0
    @State private var glowOffset2: CGFloat = 0
    @State private var glowOffset3: CGFloat = 0
    
    let tokens1 = ["SOL", "USDC", "JLP", "AVICI", "ETH", "USDG", "USD1", "GRIFFAIN", "WBTC", "ORE"]
    let tokens2 = ["JitoSOL", "mSOL", "ORE", "UMBRA", "JUP", "PYUSD", "META", "JupSOL", "GRIFFAIN", "AVICI"]
    let tokens3 = ["RAY", "xBTC", "CASH", "META", "TSLAx", "USX", "DUSD", "ORCA", "zBTC", "LOYAL"]
    let tokens4 = ["CRCLx", "MYRO", "TSLAx", "SOLO", "hyUSD", "META", "ORCA", "LOYAL", "SAROS", "zBTC"]
    let tokens5 = ["SNS", "GODL", "HNT", "PSOL", "LODE", "WLFI", "MSTRx", "UMBRA", "TSLAx", "ETH"]
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Blurred orange gradient dots
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [
                                Color(red: 1.0, green: 0.3, blue: 0.2).opacity(0.3),
                                Color(red: 1.0, green: 0.3, blue: 0.2).opacity(0.15),
                                Color.clear
                            ],
                            center: .center,
                            startRadius: 50,
                            endRadius: 200
                        )
                    )
                    .frame(width: 400, height: 400)
                    .blur(radius: 40)
                    .position(x: geometry.size.width * 0.2 + glowOffset1, y: geometry.size.height * 0.3)
                
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [
                                Color(red: 1.0, green: 0.3, blue: 0.2).opacity(0.3),
                                Color(red: 1.0, green: 0.3, blue: 0.2).opacity(0.15),
                                Color.clear
                            ],
                            center: .center,
                            startRadius: 50,
                            endRadius: 200
                        )
                    )
                    .frame(width: 400, height: 400)
                    .blur(radius: 40)
                    .position(x: geometry.size.width * 0.7 + glowOffset2, y: geometry.size.height * 0.5)
                
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [
                                Color(red: 1.0, green: 0.3, blue: 0.2).opacity(0.3),
                                Color(red: 1.0, green: 0.3, blue: 0.2).opacity(0.15),
                                Color.clear
                            ],
                            center: .center,
                            startRadius: 50,
                            endRadius: 200
                        )
                    )
                    .frame(width: 400, height: 400)
                    .blur(radius: 40)
                    .position(x: geometry.size.width * 0.4 + glowOffset3, y: geometry.size.height * 0.7)
                
                // Token rows on top
                VStack(spacing: 24) {
                    Spacer()
                    
                    // Row 1 - scrolling left to right
                    ScrollingTokenRow(tokens: tokens1, offset: offsetRow1, direction: .leftToRight)
                    
                    // Row 2 - scrolling right to left
                    ScrollingTokenRow(tokens: tokens2, offset: offsetRow2, direction: .rightToLeft)
                    
                    // Row 3 - scrolling left to right
                    ScrollingTokenRow(tokens: tokens3, offset: offsetRow3, direction: .leftToRight)
                    
                    // Row 4 - scrolling right to left
                    ScrollingTokenRow(tokens: tokens4, offset: offsetRow4, direction: .rightToLeft)
                    
                    // Row 5 - scrolling left to right
                    ScrollingTokenRow(tokens: tokens5, offset: offsetRow5, direction: .leftToRight)
                    
                    Spacer()
                }
            }
        }
        .onAppear {
            startScrolling()
            startGlowAnimation()
        }
    }
    
    private func startScrolling() {
        // Rows 1, 3, 5: Animate from +3600 to 0 (left to right scroll, 3 reps of content)
        // Rows 2, 4: Animate from 0 to -2400 (right to left scroll, 2 reps of content)
        withAnimation(.linear(duration: 90).repeatForever(autoreverses: false)) {
            offsetRow1 = 0  // From +3600 to 0 = scrolls through 3600px left-to-right
        }
        withAnimation(.linear(duration: 120).repeatForever(autoreverses: false)) {
            offsetRow2 = -2400  // From 0 to -2400 = scrolls through 2400px right-to-left
        }
        withAnimation(.linear(duration: 105).repeatForever(autoreverses: false)) {
            offsetRow3 = 0  // From +3600 to 0 = scrolls through 3600px left-to-right
        }
        withAnimation(.linear(duration: 135).repeatForever(autoreverses: false)) {
            offsetRow4 = -2400  // From 0 to -2400 = scrolls through 2400px right-to-left
        }
        withAnimation(.linear(duration: 112).repeatForever(autoreverses: false)) {
            offsetRow5 = 0  // From +3600 to 0 = scrolls through 3600px left-to-right
        }
    }
    
    private func startGlowAnimation() {
        // Slow flowing movement for gradient dots
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

// MARK: - Scrolling Token Row

struct ScrollingTokenRow: View {
    let tokens: [String]
    let offset: CGFloat
    let direction: ScrollDirection
    
    enum ScrollDirection {
        case leftToRight
        case rightToLeft
    }
    
    var body: some View {
        GeometryReader { geometry in
            HStack(spacing: 12) {
                // Duplicate tokens 5 times for seamless infinite loop
                ForEach(0..<5, id: \.self) { _ in
                    ForEach(tokens.indices, id: \.self) { index in
                        OnboardingTokenPill(ticker: tokens[index])
                    }
                }
            }
            .offset(x: offset)
        }
        .frame(height: 64)
        .clipped()
    }
}

// MARK: - Onboarding Token Pill

struct OnboardingTokenPill: View {
    let ticker: String
    
    var body: some View {
        HStack(spacing: 10) {
            // Token icon from assets
            Image(ticker)
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(width: 40, height: 40)
                .clipShape(Circle())
            
            // Ticker with $
            Text("$\(ticker)")
                .font(.system(size: 16, weight: .bold))
                .foregroundColor(.white.opacity(0.9))
                .fixedSize()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(
            ZStack {
                // Subtle blur layer
                RoundedRectangle(cornerRadius: 24)
                    .fill(Color.white.opacity(0.04))
                    .blur(radius: 2)
                
                // Main glass background
                RoundedRectangle(cornerRadius: 24)
                    .fill(Color.white.opacity(0.06))
                    .overlay(
                        RoundedRectangle(cornerRadius: 24)
                            .stroke(Color.white.opacity(0.15), lineWidth: 1.5)
                    )
            }
        )
        .shadow(color: Color.black.opacity(0.3), radius: 10, x: 0, y: 4)
        .fixedSize()
    }
}

// MARK: - Notification Card

struct NotificationCard: View {
    let title: String
    let subtitle: String
    let buttonText: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(.white)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            Text(subtitle)
                .font(.system(size: 12, weight: .regular))
                .foregroundColor(.white.opacity(0.7))
                .lineLimit(2)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            Text(buttonText)
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(.white)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(Color.white.opacity(0.15))
                .cornerRadius(12)
                .padding(.top, 4)
        }
        .frame(width: 200, alignment: .leading)
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
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
}

// MARK: - Pulsating Orb View

struct PulsatingOrbView: View {
    let orbLogoScaled: Bool
    @State private var heartbeatScale: CGFloat = 1.0
    @State private var shouldStartHeartbeat = false
    @Dependency(\.hapticFeedbackGenerator) private var hapticFeedback
    
    var body: some View {
        ZStack {
            // Glow effect (5x wider) - no scaling
            Circle()
                .fill(
                    RadialGradient(
                        colors: [
                            Color(red: 1.0, green: 0.3, blue: 0.2).opacity(0.4),
                            Color(red: 1.0, green: 0.3, blue: 0.2).opacity(0.2),
                            Color.clear
                        ],
                        center: .center,
                        startRadius: 150,
                        endRadius: 500
                    )
                )
                .frame(width: 1000, height: 1000)
                .blur(radius: 50)
            
            // Orange circle with orb icon
            ZStack {
                Circle()
                    .fill(Color(red: 1.0, green: 0.3, blue: 0.2))
                    .frame(width: 80, height: 80)
                
                Image("orb_small_white")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 52, height: 52)
            }
            .scaleEffect(heartbeatScale)
        }
        .scaleEffect(orbLogoScaled ? 0.6 : 1.0)
        .animation(.spring(response: 0.5, dampingFraction: 0.7), value: orbLogoScaled)
        .onChange(of: orbLogoScaled) { _, newValue in
            if newValue {
                // Wait for scale animation to complete, then start heartbeat
                Task {
                    try? await Task.sleep(for: .milliseconds(500))
                    shouldStartHeartbeat = true
                }
            }
        }
        .task {
            // Wait for shouldStartHeartbeat to be true
            while !shouldStartHeartbeat && !Task.isCancelled {
                try? await Task.sleep(for: .milliseconds(100))
            }
            
            // Heartbeat animation loop
            while !Task.isCancelled {
                // First beat (lub)
                await MainActor.run {
                    withAnimation(.easeOut(duration: 0.1)) {
                        heartbeatScale = 1.05
                    }
                }
                await hapticFeedback.light(intensity: 0.5)
                try? await Task.sleep(for: .milliseconds(100))
                
                await MainActor.run {
                    withAnimation(.easeIn(duration: 0.1)) {
                        heartbeatScale = 1.0
                    }
                }
                try? await Task.sleep(for: .milliseconds(150))
                
                // Second beat (dub)
                await MainActor.run {
                    withAnimation(.easeOut(duration: 0.1)) {
                        heartbeatScale = 1.03
                    }
                }
                await hapticFeedback.light(intensity: 0.4)
                try? await Task.sleep(for: .milliseconds(100))
                
                await MainActor.run {
                    withAnimation(.easeIn(duration: 0.1)) {
                        heartbeatScale = 1.0
                    }
                }
                
                // Pause before next heartbeat (doubled)
                try? await Task.sleep(for: .milliseconds(1600))
            }
        }
    }
}

