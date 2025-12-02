import Foundation

struct NewsArticle: Equatable, Identifiable, Codable {
    let id: String
    let title: String
    let subtitle: String
    let content: String
    let tokens: [NewsToken]
    let publishedAt: Date
    
    var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "d MMMM"
        return formatter.string(from: publishedAt)
    }
}

struct NewsToken: Equatable, Identifiable, Codable {
    let id: String // mint address
    let name: String
    let symbol: String
    let imageUrl: String
}

// MARK: - Data Loading

extension NewsArticle {
    static func loadFromJSON() -> [NewsArticle] {
        guard let url = Bundle.main.url(forResource: "news_data", withExtension: "json"),
              let data = try? Data(contentsOf: url) else {
            print("⚠️ Failed to load news_data.json")
            return []
        }
        
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        
        do {
            let articles = try decoder.decode([NewsArticle].self, from: data)
            print("✅ Loaded \(articles.count) news articles from JSON")
            return articles
        } catch {
            print("⚠️ Failed to decode news_data.json: \(error)")
            return []
        }
    }
    
    // Fallback mock data if JSON fails
    static let mockArticles: [NewsArticle] = [
        NewsArticle(
            id: "1",
            title: "Solana's Network Activity Hits All-Time High",
            subtitle: "Daily transactions surge past 50M as DeFi adoption accelerates",
            content: """
            # Solana Breaks Records
            
            Solana's network has reached unprecedented levels of activity, with **daily transactions exceeding 50 million** for the first time in its history.
            
            ## Key Highlights
            
            - Transaction fees remain under $0.01
            - Network uptime at 99.9%
            - New DEX protocols launching weekly
            
            This growth is largely attributed to the rise of new **DeFi protocols** and increased **NFT trading activity**. Major projects like Jupiter and Marinade Finance are seeing record volumes.
            
            Analysts predict this momentum will continue as more institutional players enter the Solana ecosystem.
            """,
            tokens: [
                NewsToken(id: "So11111111111111111111111111111111111111112", name: "Solana", symbol: "SOL", imageUrl: "we"),
                NewsToken(id: "EPjFWdd5AufqSSqeM2qN1xzybapC8G4wEGGkZwyTDt1v", name: "USD Coin", symbol: "USDC", imageUrl: "wt"),
                NewsToken(id: "JUPyiwrYJFskUPiHa7hkeR8VUtAeFoSYbKedZNsDvCN", name: "Jupiter", symbol: "JUP", imageUrl: "wwthn")
            ],
            publishedAt: Date().addingTimeInterval(-3600)
        ),
        
        NewsArticle(
            id: "2",
            title: "Major DeFi Protocol Launches on Solana",
            subtitle: "Liquidity pools offering up to 25% APY attract millions in TVL",
            content: """
            # New DeFi Powerhouse Emerges
            
            A major decentralized finance protocol has officially launched on Solana, bringing **innovative yield strategies** to the ecosystem.
            
            ## What's New
            
            - Automated liquidity optimization
            - Cross-chain bridge integration
            - Enhanced security audits by top firms
            
            Early adopters are already seeing impressive returns, with some liquidity pools offering up to **25% APY**. The protocol secured $50M in funding from leading VCs before launch.
            """,
            tokens: [
                NewsToken(id: "So11111111111111111111111111111111111111112", name: "Solana", symbol: "SOL", imageUrl: "we"),
                NewsToken(id: "mSoLzYCxHdYgdzU16g5QSh3i5K3z3KZK7ytfqcJm7So", name: "Marinade", symbol: "mSOL", imageUrl: "wt")
            ],
            publishedAt: Date().addingTimeInterval(-7200)
        ),
        
        NewsArticle(
            id: "3",
            title: "NFT Marketplace Volume Doubles",
            subtitle: "Tensor and Magic Eden report record-breaking trading activity",
            content: """
            # NFT Renaissance on Solana
            
            Trading volume on Solana's leading NFT marketplaces has **doubled in the past week**, signaling renewed interest in digital collectibles.
            
            ## Market Dynamics
            
            - Tensor leads with $100M weekly volume
            - Blue-chip collections seeing 50%+ gains
            - New creators flocking to ecosystem
            
            The surge is attributed to both new collection launches and renewed interest in established projects. Floor prices for top collections have risen significantly.
            """,
            tokens: [
                NewsToken(id: "So11111111111111111111111111111111111111112", name: "Solana", symbol: "SOL", imageUrl: "we"),
                NewsToken(id: "TNSRxcUxoT9xBG3de7PiJyTDYu7kskLqcpddxnEJAS6", name: "Tensor", symbol: "TNSR", imageUrl: "wwthn")
            ],
            publishedAt: Date().addingTimeInterval(-10800)
        ),
        
        NewsArticle(
            id: "4",
            title: "Stablecoin Adoption Accelerates",
            subtitle: "USDC transfers on Solana surpass Ethereum for first time",
            content: """
            # Stablecoin Milestone Achieved
            
            For the first time, **USDC transfer volume on Solana** has exceeded that of Ethereum, marking a significant shift in DeFi activity.
            
            ## Breaking Down the Numbers
            
            - Daily USDC transfers: $2.3B
            - Average transaction cost: $0.0001
            - Settlement time: Sub-second
            
            This milestone highlights Solana's efficiency advantage for payments and DeFi. Major payment processors are now integrating Solana for **instant, low-cost settlements**.
            """,
            tokens: [
                NewsToken(id: "EPjFWdd5AufqSSqeM2qN1xzybapC8G4wEGGkZwyTDt1v", name: "USD Coin", symbol: "USDC", imageUrl: "wt"),
                NewsToken(id: "So11111111111111111111111111111111111111112", name: "Solana", symbol: "SOL", imageUrl: "we")
            ],
            publishedAt: Date().addingTimeInterval(-14400)
        ),
        
        NewsArticle(
            id: "5",
            title: "Institutional Interest Grows",
            subtitle: "Major funds allocate to Solana ecosystem projects",
            content: """
            # Wall Street Looks to Solana
            
            Several major institutional investors have announced significant allocations to Solana-based projects, signaling growing mainstream acceptance.
            
            ## Investment Highlights
            
            - $500M in new capital commitments
            - Focus on DeFi infrastructure
            - Long-term strategic partnerships
            
            Leading venture capital firms are particularly interested in projects building **cross-chain infrastructure** and **real-world asset tokenization** on Solana.
            """,
            tokens: [
                NewsToken(id: "So11111111111111111111111111111111111111112", name: "Solana", symbol: "SOL", imageUrl: "we"),
                NewsToken(id: "JUPyiwrYJFskUPiHa7hkeR8VUtAeFoSYbKedZNsDvCN", name: "Jupiter", symbol: "JUP", imageUrl: "wwthn")
            ],
            publishedAt: Date().addingTimeInterval(-18000)
        ),
        
        NewsArticle(
            id: "6",
            title: "Gaming Projects Launch Season 2",
            subtitle: "Play-to-earn games attract millions of new users",
            content: """
            # Gaming Takes Center Stage
            
            Multiple gaming projects on Solana are launching major updates, bringing **immersive experiences** and new economic models to players worldwide.
            
            ## Gaming Evolution
            
            - 5M+ active gamers on-chain
            - New AAA partnerships announced
            - Mobile-first gaming experiences
            
            The low transaction costs and fast finality make Solana ideal for **blockchain gaming**, where frequent micro-transactions are essential.
            """,
            tokens: [
                NewsToken(id: "So11111111111111111111111111111111111111112", name: "Solana", symbol: "SOL", imageUrl: "we")
            ],
            publishedAt: Date().addingTimeInterval(-21600)
        ),
        
        NewsArticle(
            id: "7",
            title: "Cross-Chain Bridge Security Enhanced",
            subtitle: "New protocols implement advanced security measures",
            content: """
            # Bridging Gets Safer
            
            Leading cross-chain bridge protocols on Solana have implemented **enhanced security measures**, including multi-signature requirements and insurance pools.
            
            ## Security First
            
            - $100M insurance fund established
            - Real-time monitoring systems
            - Third-party security audits
            
            These improvements come after the industry learned valuable lessons from past exploits. Users can now bridge assets with greater confidence.
            """,
            tokens: [
                NewsToken(id: "So11111111111111111111111111111111111111112", name: "Solana", symbol: "SOL", imageUrl: "we"),
                NewsToken(id: "EPjFWdd5AufqSSqeM2qN1xzybapC8G4wEGGkZwyTDt1v", name: "USD Coin", symbol: "USDC", imageUrl: "wt")
            ],
            publishedAt: Date().addingTimeInterval(-25200)
        ),
        
        NewsArticle(
            id: "8",
            title: "Mobile Wallet Adoption Soars",
            subtitle: "New generation discovers crypto through mobile-first apps",
            content: """
            # Mobile-First Revolution
            
            Mobile wallet downloads have **surged 300%** this quarter, with younger demographics leading the adoption of Solana-based payment apps.
            
            ## Mobile Momentum
            
            - 10M+ mobile wallet users
            - Seamless onboarding experience
            - Integration with popular apps
            
            The ease of use and instant transactions are making Solana the **preferred choice** for mobile payments and remittances globally.
            """,
            tokens: [
                NewsToken(id: "So11111111111111111111111111111111111111112", name: "Solana", symbol: "SOL", imageUrl: "we"),
                NewsToken(id: "EPjFWdd5AufqSSqeM2qN1xzybapC8G4wEGGkZwyTDt1v", name: "USD Coin", symbol: "USDC", imageUrl: "wt")
            ],
            publishedAt: Date().addingTimeInterval(-28800)
        ),
        
        NewsArticle(
            id: "9",
            title: "Developer Activity Reaches New Peak",
            subtitle: "Thousands of new projects building on Solana",
            content: """
            # Developer Ecosystem Thrives
            
            The number of active developers building on Solana has reached an **all-time high**, with thousands of new projects in various stages of development.
            
            ## Developer Stats
            
            - 5,000+ active developers
            - 100+ projects launching monthly
            - Growing education initiatives
            
            Enhanced developer tools, comprehensive documentation, and strong community support are driving this growth in the **Solana developer ecosystem**.
            """,
            tokens: [
                NewsToken(id: "So11111111111111111111111111111111111111112", name: "Solana", symbol: "SOL", imageUrl: "we")
            ],
            publishedAt: Date().addingTimeInterval(-32400)
        ),
        
        NewsArticle(
            id: "10",
            title: "Real-World Asset Tokenization Expands",
            subtitle: "Traditional assets moving on-chain via Solana",
            content: """
            # TradFi Meets DeFi
            
            Real-world assets totaling **$1B+ are now tokenized** on Solana, including real estate, commodities, and private equity.
            
            ## Asset Revolution
            
            - 24/7 trading of tokenized assets
            - Fractional ownership opportunities
            - Instant settlement
            
            This trend represents a **fundamental shift** in how traditional assets are traded, offering unprecedented liquidity and accessibility to global investors.
            """,
            tokens: [
                NewsToken(id: "So11111111111111111111111111111111111111112", name: "Solana", symbol: "SOL", imageUrl: "we"),
                NewsToken(id: "EPjFWdd5AufqSSqeM2qN1xzybapC8G4wEGGkZwyTDt1v", name: "USD Coin", symbol: "USDC", imageUrl: "wt")
            ],
            publishedAt: Date().addingTimeInterval(-36000)
        )
    ]
}

// MARK: - SwiftUI Components

import SwiftUI

/// Token Pill component used to display token badges in news articles
struct TokenPill: View {
    let token: NewsToken
    
    var body: some View {
        HStack(spacing: 6) {
            TokenImageView(
                iconURL: token.imageUrl,
                fallbackText: token.symbol,
                size: 20,
                tokenMint: token.id
            )
            
            Text(token.symbol)
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(.tokens.textPrimary)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(Color(white: 0.95))
        .clipShape(Capsule())
    }
}

