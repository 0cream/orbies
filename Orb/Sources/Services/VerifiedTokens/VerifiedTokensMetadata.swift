import Foundation

// MARK: - Models

struct VerifiedTokenMetadata: Codable {
    let mint: String
    let ticker: String
    let name: String
    let imageUrl: String
}

// MARK: - Service

final class VerifiedTokensMetadata: @unchecked Sendable {
    static let shared = VerifiedTokensMetadata()
    
    private let tokens: [String: VerifiedTokenMetadata]
    
    private init() {
        var loadedTokens: [String: VerifiedTokenMetadata] = [:]
        
        guard let url = Bundle.main.url(forResource: "verified_tokens_metadata", withExtension: "json"),
              let data = try? Data(contentsOf: url),
              let tokenArray = try? JSONDecoder().decode([VerifiedTokenMetadata].self, from: data) else {
            print("⚠️ Failed to load verified_tokens_metadata.json")
            self.tokens = [:]
            return
        }
        
        // Index by mint address for O(1) lookup
        for token in tokenArray {
            loadedTokens[token.mint] = token
        }
        
        self.tokens = loadedTokens
        print("✅ Loaded \(loadedTokens.count) verified tokens metadata")
    }
    
    /// Get token metadata by mint address
    func getToken(byMint mint: String) -> VerifiedTokenMetadata? {
        return tokens[mint]
    }
    
    /// Get token metadata by ticker/symbol (case-insensitive)
    func getToken(byTicker ticker: String) -> VerifiedTokenMetadata? {
        return tokens.values.first { $0.ticker.lowercased() == ticker.lowercased() }
    }
    
    /// Get image URL for a token by mint address
    func getImageUrl(forMint mint: String) -> String? {
        return tokens[mint]?.imageUrl
    }
    
    /// Get image URL for a token by ticker/symbol
    func getImageUrl(forTicker ticker: String) -> String? {
        return getToken(byTicker: ticker)?.imageUrl
    }
}

