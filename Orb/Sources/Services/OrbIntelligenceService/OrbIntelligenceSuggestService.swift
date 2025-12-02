import Dependencies
import Foundation

// MARK: - Protocol

protocol OrbIntelligenceSuggestService: Sendable {
    func setup(suggests: [String])
    func used()
    func observe() -> AsyncStream<[String]>
}

// MARK: - Live Implementation

final class LiveOrbIntelligenceSuggestService: OrbIntelligenceSuggestService {
    private nonisolated(unsafe) var suggests: [String] = [] {
        didSet {
            continuation?.yield(suggests)
        }
    }
    
    private nonisolated(unsafe) var continuation: AsyncStream<[String]>.Continuation?
    
    init() {
        
    }
    
    func setup(suggests: [String]) {
        self.suggests = suggests
    }
    
    func used() {
        suggests = []
    }
    
    func observe() -> AsyncStream<[String]> {
        AsyncStream { [weak self] continuation in
            self?.continuation = continuation
            
            continuation.onTermination = { [weak self] _ in
                self?.continuation = nil
            }
        }
    }
}

// MARK: - Mock Implementation

struct MockOrbIntelligenceSuggestService: OrbIntelligenceSuggestService {
    func setup(suggests: [String]) {
        // Mock implementation
    }
    
    func used() {
        // Mock implementation
    }
    
    func observe() -> AsyncStream<[String]> {
        AsyncStream { _ in }
    }
}

// MARK: - Dependency

private enum OrbIntelligenceSuggestServiceKey: DependencyKey {
    static let liveValue: any OrbIntelligenceSuggestService = LiveOrbIntelligenceSuggestService()
    static let testValue: any OrbIntelligenceSuggestService = MockOrbIntelligenceSuggestService()
}

extension DependencyValues {
    var orbIntelligenceSuggestService: any OrbIntelligenceSuggestService {
        get { self[OrbIntelligenceSuggestServiceKey.self] }
        set { self[OrbIntelligenceSuggestServiceKey.self] = newValue }
    }
}

