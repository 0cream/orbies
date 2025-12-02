import SwiftUI

// MARK: - News Timeline View

struct NewsTimelineView: View {
    let articles: [NewsArticle]
    let chartData: [ChartDataPoint]
    let onArticleTap: (NewsArticle) -> Void
    
    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                // Timeline base line
                Rectangle()
                    .fill(Color.white.opacity(0.1))
                    .frame(height: 1)
                
                // Article markers
                ForEach(articles) { article in
                    if let position = calculatePosition(for: article, width: geometry.size.width) {
                        ArticleMarker()
                            .onTapGesture {
                                onArticleTap(article)
                            }
                            .offset(x: position - 4) // Center the circle
                    }
                }
            }
        }
        .frame(height: 20)
    }
    
    private func calculatePosition(for article: NewsArticle, width: CGFloat) -> CGFloat? {
        guard let earliestPoint = chartData.first?.timestamp,
              let latestPoint = chartData.last?.timestamp else {
            return nil
        }
        
        let timeRange = latestPoint.timeIntervalSince(earliestPoint)
        guard timeRange > 0 else { return nil }
        
        let articleOffset = article.publishedAt.timeIntervalSince(earliestPoint)
        let ratio = articleOffset / timeRange
        
        return CGFloat(ratio) * width
    }
}

// MARK: - Article Marker

private struct ArticleMarker: View {
    var body: some View {
        ZStack {
            // Outer ring
            Circle()
                .stroke(Color(red: 1.0, green: 0.3, blue: 0.2).opacity(0.3), lineWidth: 1)
                .frame(width: 16, height: 16)
            
            // Inner dot
            Circle()
                .fill(Color(red: 1.0, green: 0.3, blue: 0.2))
                .frame(width: 8, height: 8)
        }
    }
}

