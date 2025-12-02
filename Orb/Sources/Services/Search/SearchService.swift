import Dependencies
import Foundation

// MARK: - Models

struct SearchTokenResult: Codable, Identifiable, Sendable {
    let address: String
    let symbol: String?
    let name: String?
    let decimals: Int?
    let logoURI: String?
    let addedAt: Double
    let lastIndexed: Double
    let isActive: Bool
    let lastPrice: TokenPrice?
    
    var id: String { address }
    
    struct TokenPrice: Codable, Sendable {
        let tokenAddress: String
        let timestamp: Double
        let price: Double
        let source: String
    }
}

struct SearchTokensResponse: Codable, Sendable {
    let success: Bool
    let data: [SearchTokenResult]
    let count: Int
    let query: String
}

// MARK: - Service Protocol

protocol SearchService: Actor {
    func searchTokens(query: String) async throws -> [SearchTokenResult]
}

// MARK: - Live Implementation

actor LiveSearchService: SearchService {
    
    private let baseURL = "https://orb-invest-backend.onrender.com"
    
    func searchTokens(query: String) async throws -> [SearchTokenResult] {
        guard query.count >= 2 else {
            return []
        }
        
        print("🔍 SearchService: Searching for '\(query)'")
        
        guard let encodedQuery = query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) else {
            return []
        }
        
        let urlString = "\(baseURL)/api/tokens/search?q=\(encodedQuery)"
        guard let url = URL(string: urlString) else {
            throw NSError(domain: "SearchService", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid URL"])
        }
        
        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            let response = try JSONDecoder().decode(SearchTokensResponse.self, from: data)
            
            print("✅ SearchService: Found \(response.data.count) results")
            return response.data
        } catch {
            print("❌ SearchService: Search failed - \(error)")
            throw error
        }
    }
}

// MARK: - Dependency

extension DependencyValues {
    var searchService: any SearchService {
        get { self[SearchServiceKey.self] }
        set { self[SearchServiceKey.self] = newValue }
    }
}

private enum SearchServiceKey: DependencyKey {
    static let liveValue: any SearchService = LiveSearchService()
}

