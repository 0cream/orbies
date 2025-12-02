import Dependencies
import Foundation

// MARK: - Protocol

protocol NewsService: Sendable {
    func fetchNews() async throws -> [NewsArticle]
}

// MARK: - Live Implementation

actor LiveNewsService: NewsService {
    @Dependency(\.orbBackendService)
    private var orbBackendService: OrbBackendService
    
    func fetchNews() async throws -> [NewsArticle] {
        return try await orbBackendService.getEvents()
    }
}

// MARK: - Mock Implementation

struct MockNewsService: NewsService {
    func fetchNews() async throws -> [NewsArticle] {
        // Return empty array for tests
        return []
    }
}

// MARK: - Dependency

private enum NewsServiceKey: DependencyKey {
    static let liveValue: any NewsService = LiveNewsService()
    static let testValue: any NewsService = MockNewsService()
}

extension DependencyValues {
    var newsService: any NewsService {
        get { self[NewsServiceKey.self] }
        set { self[NewsServiceKey.self] = newValue }
    }
}

