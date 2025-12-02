import SwiftUI
import NukeUI

/// Reusable image view that handles SVGs, Arweave URLs, and regular images
/// with shimmer loading states and verified metadata fallback
struct TokenImageView: View {
    let url: URL?
    let fallbackText: String
    let size: CGFloat
    
    init(url: URL?, fallbackText: String, size: CGFloat = 44) {
        self.url = url
        self.fallbackText = fallbackText
        self.size = size
    }
    
    init(iconURL: String?, fallbackText: String, size: CGFloat = 44, tokenMint: String? = nil) {
        // Try provided URL first, but validate it's a proper URL
        var finalURL: URL? = nil
        
        if let urlString = iconURL, !urlString.isEmpty {
            // Only use if it's a valid HTTP/HTTPS URL
            if let url = URL(string: urlString),
               (url.scheme == "http" || url.scheme == "https") {
                finalURL = url
            }
        }
        
        // If no valid URL provided, try verified metadata
        if finalURL == nil {
            if let mint = tokenMint,
               let verifiedImageUrl = VerifiedTokensMetadata.shared.getImageUrl(forMint: mint) {
                finalURL = URL(string: verifiedImageUrl)
            } else if let verifiedImageUrl = VerifiedTokensMetadata.shared.getImageUrl(forTicker: fallbackText) {
                // Fallback to ticker lookup
                finalURL = URL(string: verifiedImageUrl)
            }
        }
        
        self.url = finalURL
        self.fallbackText = fallbackText
        self.size = size
    }
    
    var body: some View {
        Group {
            if let url = url {
                let urlString = url.absoluteString
                let isSVG = urlString.hasSuffix(".svg")
                
                if isSVG {
                    // SVG handling
                    SVGImageView(url: url, size: CGSize(width: size, height: size))
                } else {
                    // Regular image handling (PNG, JPEG, Arweave, etc.)
                    LazyImage(url: url) { state in
                        if let image = state.image {
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .frame(width: size, height: size)
                                .clipShape(Circle())
                        } else if state.error != nil {
                            fallbackView
                        } else {
                            // Loading state with shimmer
                            Circle()
                                .fill(Color.white.opacity(0.08))
                                .overlay(
                                    ShimmerView()
                                        .clipShape(Circle())
                                )
                                .frame(width: size, height: size)
                        }
                    }
                }
            } else {
                fallbackView
            }
        }
        .frame(width: size, height: size)
    }
    
    private var fallbackView: some View {
        Circle()
            .fill(Color.white.opacity(0.12))
            .overlay(
                Text(fallbackText.prefix(1).uppercased())
                    .font(.system(size: size * 0.4, weight: .semibold))
                    .foregroundStyle(.white.opacity(0.6))
            )
    }
}

// MARK: - Shimmer Effect

private struct ShimmerView: View {
    @State private var phase: CGFloat = 0
    
    var body: some View {
        GeometryReader { geometry in
            LinearGradient(
                colors: [
                    Color.white.opacity(0.05),
                    Color.white.opacity(0.15),
                    Color.white.opacity(0.05)
                ],
                startPoint: .leading,
                endPoint: .trailing
            )
            .frame(width: geometry.size.width * 2)
            .offset(x: phase * geometry.size.width * 2 - geometry.size.width)
            .onAppear {
                withAnimation(.linear(duration: 1.5).repeatForever(autoreverses: false)) {
                    phase = 1
                }
            }
        }
    }
}

