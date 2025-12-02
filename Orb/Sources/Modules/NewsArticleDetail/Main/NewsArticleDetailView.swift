import SwiftUI
import ComposableArchitecture
import SFSafeSymbols

@ViewAction(for: NewsArticleDetailFeature.self)
struct NewsArticleDetailView: View {
    let store: StoreOf<NewsArticleDetailFeature>
    
    @State private var glowOffset1: CGFloat = 0
    @State private var glowOffset2: CGFloat = 0
    @State private var glowOffset3: CGFloat = 0
    @State private var visiblePills: Set<String> = []
    @Dependency(\.hapticFeedbackGenerator) private var hapticFeedback
    
    var body: some View {
        ScrollView(.vertical) {
            VStack(alignment: .leading, spacing: 0) {
                // Hero section with floating token pills
                ZStack {
                    // Black background
                    Color.black
                    
                    // Animated blurred orange gradient dots
                    GeometryReader { geometry in
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
                    }
                    
                    // Floating token pills (randomly positioned)
                    GeometryReader { geometry in
                        ForEach(Array(store.article.tokens.enumerated()), id: \.element.id) { index, token in
                            FloatingTokenPill(token: token, size: pillSize(for: index))
                                .position(
                                    x: pillPosition(for: index, in: geometry.size).x,
                                    y: pillPosition(for: index, in: geometry.size).y
                                )
                                .scaleEffect(visiblePills.contains(token.id) ? 1 : 0.3)
                                .opacity(visiblePills.contains(token.id) ? 1 : 0)
                                .animation(.spring(response: 0.5, dampingFraction: 0.6), value: visiblePills)
                        }
                    }
                    
                    // Title overlay (bottom-leading)
                    VStack {
                        Spacer()
                        Text(store.article.title)
                            .font(.system(size: 28, weight: .bold))
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.horizontal, 24)
                            .padding(.bottom, 24)
                            .shadow(color: .black.opacity(0.3), radius: 8, x: 0, y: 2)
                    }
                    
                    // Close button (top-trailing)
                    VStack {
                        HStack {
                            Spacer()
                            Button {
                                send(.didTapClose)
                            } label: {
                                Image(systemSymbol: .xmarkCircleFill)
                                    .font(.system(size: 32, weight: .medium))
                                    .foregroundStyle(.white.opacity(0.9))
                                    .shadow(color: .black.opacity(0.2), radius: 4, x: 0, y: 2)
                            }
                            .padding(20)
                        }
                        Spacer()
                    }
                }
                .frame(height: 280)
                
                // Content below gradient
                VStack(alignment: .leading, spacing: 20) {
                    // Category
                    HStack(spacing: 4) {
                        Circle()
                            .fill(.blue)
                            .frame(width: 6, height: 6)
                        
                        Text("SOLANA")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundStyle(.white.opacity(0.6))
                    }
                    
                    // Date
                    Text(store.article.formattedDate.uppercased())
                        .font(.system(size: 11, weight: .bold))
                        .foregroundStyle(.white.opacity(0.6))
                    
                    // Subtitle
                    Text(store.article.subtitle)
                        .font(.system(size: 17, weight: .regular))
                        .foregroundStyle(.white.opacity(0.8))
                    
                    // Tokens
                    if !store.article.tokens.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Related Tokens")
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundStyle(.white.opacity(0.6))
                            
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 12) {
                                    ForEach(store.article.tokens) { token in
                                        TokenPill(token: token)
                                    }
                                }
                            }
                        }
                    }
                    
                    Divider()
                        .background(.white.opacity(0.2))
                        .padding(.vertical, 8)
                    
                    // Markdown content
                    Text(parseMarkdown(store.article.content))
                        .font(.system(size: 17, weight: .regular))
                        .foregroundStyle(.white)
                        .lineSpacing(6)
                }
                .padding(24)
                .padding(.bottom, 120) // Add space for tab bar and orb button
            }
        }
        .scrollIndicators(.hidden)
        .background(Color.black)
        .navigationBarHidden(true)
        .onAppear {
            startGlowAnimation()
            startPillAnimation()
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
    
    private func startPillAnimation() {
        // Show pills one by one with 150ms intervals
        for (index, token) in store.article.tokens.enumerated() {
            Task {
                try? await Task.sleep(nanoseconds: UInt64(index) * 150_000_000) // 150ms between each
                await MainActor.run {
                    visiblePills.insert(token.id)
                }
                // Add haptic feedback for each pill pop
                await hapticFeedback.light(intensity: 0.8)
            }
        }
    }
    
    private func parseMarkdown(_ markdown: String) -> AttributedString {
        do {
            // Parse markdown directly - \n in JSON is already a real newline
            var attributedString = try AttributedString(markdown: markdown, options: AttributedString.MarkdownParsingOptions(interpretedSyntax: .inlineOnlyPreservingWhitespace))
            return attributedString
        } catch {
            // Fallback to plain text if markdown parsing fails
            return AttributedString(markdown)
        }
    }
    
    // Helper functions for pill positioning and sizing
    private func pillSize(for index: Int) -> CGFloat {
        // Vary sizes between small, medium, and large
        let sizes: [CGFloat] = [60, 80, 100, 70, 90, 65, 85, 75]
        return sizes[index % sizes.count]
    }
    
    private func pillPosition(for index: Int, in size: CGSize) -> CGPoint {
        // Create deterministic but varied positions based on index and article ID
        // Use hashValue but keep it bounded to avoid overflow
        let hashSeed = abs(store.article.id.hashValue % 1000)
        let seed = (index + hashSeed) % 1000
        
        // Define regions to avoid center (where title is)
        let xPositions: [Double] = [0.15, 0.25, 0.35, 0.65, 0.75, 0.85]
        let yPositions: [Double] = [0.2, 0.3, 0.4, 0.5, 0.6]
        
        let xIndex = abs((seed * 7)) % xPositions.count
        let yIndex = abs((seed * 11)) % yPositions.count
        
        let x = size.width * xPositions[xIndex]
        let y = size.height * yPositions[yIndex]
        
        return CGPoint(x: x, y: y)
    }
}

// MARK: - Floating Token Pill

struct FloatingTokenPill: View {
    let token: NewsToken
    let size: CGFloat
    
    @State private var isAnimating = false
    
    var body: some View {
        HStack(spacing: 8) {
            TokenImageView(
                iconURL: token.imageUrl,
                fallbackText: token.symbol,
                size: size * 0.4,
                tokenMint: token.id
            )
            
            Text(token.symbol)
                .font(.system(size: size * 0.25, weight: .semibold))
                .foregroundStyle(.white)
        }
        .padding(.horizontal, size * 0.25)
        .padding(.vertical, size * 0.2)
        .background(
            ZStack {
                // Blur layer
                Capsule()
                    .fill(Color.white.opacity(0.05))
                    .blur(radius: 8)
                
                // Main background
                Capsule()
                    .fill(Color.white.opacity(0.15))
                    .background(
                        Capsule()
                            .stroke(Color.white.opacity(0.25), lineWidth: 1)
                    )
            }
        )
        .shadow(color: Color.black.opacity(0.3), radius: 10, x: 0, y: 4)
        .scaleEffect(isAnimating ? 1.05 : 1.0)
        .opacity(isAnimating ? 0.9 : 1.0)
        .animation(
            Animation.easeInOut(duration: Double.random(in: 2.0...3.5))
                .repeatForever(autoreverses: true),
            value: isAnimating
        )
        .onAppear {
            // Stagger animations
            DispatchQueue.main.asyncAfter(deadline: .now() + Double.random(in: 0...0.5)) {
                isAnimating = true
            }
        }
    }
}

