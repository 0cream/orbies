import Dependencies
import Foundation
import OpenAPIClient

// MARK: - Protocol

protocol OrbBackendService: Sendable {
    /// Submit tokens for historical price indexing
    /// The backend will queue these tokens and start fetching historical prices
    func addTokensBatch(tokens: [TokenIndexRequest]) async throws -> AddTokensBatchResponse
    
    /// Get historical prices for a specific token
    func getAllPrices(tokenAddress: String) async throws -> AllPricesResponse
    
    /// Get the latest real-time price for a token
    func getRealtimePrice(tokenAddress: String) async throws -> RealtimePriceResponse
    
    /// Get news events
    func getEvents() async throws -> [NewsArticle]
    
    /// Update all news events (admin only)
    func updateEvents(eventsJSON: String) async throws -> UpdateEventsResponse
}

// MARK: - Models

struct TokenIndexRequest: Codable, Sendable {
    let address: String
    let symbol: String?
    let name: String?
    
    init(address: String, symbol: String?, name: String?) {
        self.address = address
        self.symbol = symbol
        self.name = name
    }
}

struct AddTokensBatchResponse: Codable, Sendable {
    let success: Bool
    let data: BatchData
    let message: String
    let skipped: [SkippedToken]?
    let rejected: [RejectedToken]?
    let queue: QueueInfo
    
    struct BatchData: Codable, Sendable {
        let accepted: Int
        let skipped: Int
        let rejected: Int
        let total: Int
    }
    
    struct SkippedToken: Codable, Sendable {
        let address: String
        let symbol: String?
        let status: String // "skipped"
        let reason: String
    }
    
    struct RejectedToken: Codable, Sendable {
        let address: String
        let symbol: String?
        let status: String // "error"
        let reason: String
    }
    
    struct QueueInfo: Codable, Sendable {
        let length: Int
        let isProcessing: Bool
        let currentToken: String?
    }
}

struct AllPricesResponse: Codable, Sendable {
    let success: Bool
    let data: PriceData
    let indexing: IndexingInfo
    
    struct PriceData: Codable, Sendable {
        let tokenAddress: String
        let day: [StoredPrice]
        let week: [StoredPrice]
        let month: [StoredPrice]
        let year: [StoredPrice]
    }
    
    struct IndexingInfo: Codable, Sendable {
        let status: String // "complete", "indexing", "queued", "pending"
        let message: String?
        let lastIndexed: Int // milliseconds
    }
}

struct RealtimePriceResponse: Codable, Sendable {
    let success: Bool
    let data: StoredPrice
}

struct StoredPrice: Codable, Sendable {
    let tokenAddress: String
    let price: Double
    let timestamp: Int // milliseconds
    let source: String // "birdeye" or "jupiter"
    let interval: String? // "3m", "30m", "8H" (only for historical)
}

struct UpdateEventsResponse: Codable, Sendable {
    let success: Bool
    let message: String
    let count: Int
}

// MARK: - Live Implementation

actor LiveOrbBackendService: OrbBackendService {
    
    private enum Constants {
        static let baseURL = "https://orb-invest-backend.onrender.com"
        // static let baseURL = "http://localhost:3001" // For local development
    }
    
    private let urlSession: URLSession
    
    init() {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 30
        config.timeoutIntervalForResource = 60
        self.urlSession = URLSession(configuration: config)
    }
    
    // MARK: - API Methods
    
    func addTokensBatch(tokens: [TokenIndexRequest]) async throws -> AddTokensBatchResponse {
        let url = URL(string: "\(Constants.baseURL)/api/tokens/batch")!
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.timeoutInterval = 30 // 30 second timeout
        
        let body = ["tokens": tokens]
        request.httpBody = try JSONEncoder().encode(body)
        
        print("🚀 OrbBackendService: Submitting \(tokens.count) tokens for indexing")
        print("   Tokens: \(tokens.map { $0.symbol ?? String($0.address.prefix(8)) + "..." }.joined(separator: ", "))")
        
        let startTime = Date()
        let (data, response) = try await urlSession.data(for: request)
        let duration = Date().timeIntervalSince(startTime)
        print("   ⏱️  Request took: \(String(format: "%.2f", duration))s")
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw OrbBackendError.invalidResponse
        }
        
        guard httpResponse.statusCode == 200 else {
            throw OrbBackendError.httpError(statusCode: httpResponse.statusCode, data: data)
        }
        
        let result = try JSONDecoder().decode(AddTokensBatchResponse.self, from: data)
        
        print("✅ OrbBackendService: Batch submitted")
        print("   Accepted: \(result.data.accepted)")
        print("   Rejected: \(result.data.rejected)")
        print("   Total: \(result.data.total)")
        print("   Queue: \(result.queue.length) tokens")
        print("   Message: \(result.message)")
        
        // Log rejected tokens if any
        if let rejected = result.rejected, !rejected.isEmpty {
            print("   ⚠️ Rejected tokens:")
            for token in rejected {
                print("      ❌ \(token.address): \(token.reason)")
            }
        }
        
        return result
    }
    
    func getAllPrices(tokenAddress: String) async throws -> AllPricesResponse {
        let url = URL(string: "\(Constants.baseURL)/api/tokens/\(tokenAddress)/prices")!
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        
        print("📊 OrbBackendService: Fetching prices for \(tokenAddress.prefix(8))...")
        
        let (data, response) = try await urlSession.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw OrbBackendError.invalidResponse
        }
        
        guard httpResponse.statusCode == 200 else {
            // If 404 - token not indexed yet
            if httpResponse.statusCode == 404 {
                throw OrbBackendError.indexingNotComplete(
                    status: "not_indexed",
                    message: "Token not yet submitted for indexing"
                )
            }
            // If 502 - backend error (likely token still being indexed)
            if httpResponse.statusCode == 502 {
                throw OrbBackendError.indexingNotComplete(
                    status: "indexing",
                    message: "Token is being indexed, please try again later"
                )
            }
            throw OrbBackendError.httpError(statusCode: httpResponse.statusCode, data: data)
        }
        
        let result = try JSONDecoder().decode(AllPricesResponse.self, from: data)
        
        // Check indexing status
        guard result.indexing.status == "complete" else {
            let statusIcon: String
            switch result.indexing.status {
            case "indexing": statusIcon = "⏳"
            case "queued": statusIcon = "⏸️"
            case "pending": statusIcon = "⏸️"
            default: statusIcon = "❓"
            }
            
            print("\(statusIcon) OrbBackendService: Indexing not complete - \(result.indexing.status)")
            if let message = result.indexing.message {
                print("   \(message)")
            }
            
            throw OrbBackendError.indexingNotComplete(
                status: result.indexing.status,
                message: result.indexing.message
            )
        }
        
        // Indexing complete - log success
        print("✅ OrbBackendService: Indexing complete")
        print("   Day: \(result.data.day.count) points")
        print("   Week: \(result.data.week.count) points")
        print("   Month: \(result.data.month.count) points")
        print("   Year: \(result.data.year.count) points")
        
        return result
    }
    
    func getRealtimePrice(tokenAddress: String) async throws -> RealtimePriceResponse {
        let url = URL(string: "\(Constants.baseURL)/api/tokens/\(tokenAddress)/prices/realtime")!
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        
        let (data, response) = try await urlSession.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw OrbBackendError.invalidResponse
        }
        
        guard httpResponse.statusCode == 200 else {
            throw OrbBackendError.httpError(statusCode: httpResponse.statusCode, data: data)
        }
        
        return try JSONDecoder().decode(RealtimePriceResponse.self, from: data)
    }
    
    func getEvents() async throws -> [NewsArticle] {
        print("🚀 OrbBackendService: Fetching events using OpenAPI client")
        
        do {
            let response = try await EventsAPI.getEvents()
            
            // Convert ImportantEvent to NewsArticle
            let articles = response.data.map { event in
                NewsArticle(
                    id: event.id,
                    title: event.title,
                    subtitle: event.subtitle,
                    content: event.content,
                    tokens: event.tokens.map { token in
                        NewsToken(
                            id: token.id,
                            name: token.name,
                            symbol: token.symbol,
                            imageUrl: token.imageUrl
                        )
                    },
                    publishedAt: event.publishedAt
                )
            }
            
            print("✅ OrbBackendService: Fetched \(articles.count) news articles")
            return articles
        } catch {
            print("❌ OrbBackendService: Failed to fetch events: \(error)")
            throw error
        }
    }
    
    func updateEvents(eventsJSON: String) async throws -> UpdateEventsResponse {
        print("🚀 OrbBackendService: Updating events using OpenAPI client")
        
        // Parse JSON to ImportantEvent array
        guard let jsonData = eventsJSON.data(using: .utf8).map({ String(data: $0, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines).data(using: .utf8) ?? $0 }) else {
            throw OrbBackendError.invalidJSON
        }
        
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        
        let events: [ImportantEvent]
        do {
            events = try decoder.decode([ImportantEvent].self, from: jsonData)
        } catch {
            print("❌ OrbBackendService: Failed to parse events JSON: \(error)")
            throw OrbBackendError.invalidJSON
        }
        
        print("📊 OrbBackendService: Parsed \(events.count) events")
        
        // Create request and call API (uses shared config with correct base path)
        let request = ReplaceEventsRequest(events: events)
        
        do {
            let response = try await AdminAPI.replaceEvents(replaceEventsRequest: request)
            print("✅ OrbBackendService: Events updated - \(response.count) events")
            
            return UpdateEventsResponse(
                success: response.success,
                message: response.message,
                count: response.count
            )
        } catch {
            print("❌ OrbBackendService: Failed to update events: \(error)")
            throw error
        }
    }
}

// MARK: - Error

enum OrbBackendError: Error, LocalizedError {
    case invalidResponse
    case httpError(statusCode: Int, data: Data)
    case indexingNotComplete(status: String, message: String?)
    case invalidJSON
    
    var errorDescription: String? {
        switch self {
        case .invalidResponse:
            return "Invalid response from server"
        case .httpError(let statusCode, let data):
            let message = String(data: data, encoding: .utf8) ?? "Unknown error"
            return "HTTP \(statusCode): \(message)"
        case .indexingNotComplete(let status, let message):
            if let message = message {
                return "Indexing \(status): \(message)"
            }
            return "Token indexing \(status). Price data not yet available."
        case .invalidJSON:
            return "Invalid JSON format"
        }
    }
}

// MARK: - Dependency

extension DependencyValues {
    var orbBackendService: OrbBackendService {
        get { self[OrbBackendServiceKey.self] }
        set { self[OrbBackendServiceKey.self] = newValue }
    }
}

private enum OrbBackendServiceKey: DependencyKey {
    static let liveValue: OrbBackendService = LiveOrbBackendService()
    static let testValue: OrbBackendService = { preconditionFailure() }()
}

