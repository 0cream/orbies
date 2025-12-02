import Foundation

public actor AsyncPublisher<Element: Sendable> {
    public typealias ElementsStream = AsyncStream<Element>
    public typealias ElementsStreamContinuation = ElementsStream.Continuation
    public typealias BufferingPolicy = ElementsStreamContinuation.BufferingPolicy
    
    private let bufferingPolicy: BufferingPolicy
    private let verbose: Bool
    private var buffer: [Element] = []
    private var subscribers: [UUID: ElementsStreamContinuation] = [:]
    
    public var hasSubscribers: Bool { !subscribers.isEmpty }
    public var lastValue: Element? { buffer.last }
    
    public init(bufferingPolicy: BufferingPolicy = .bufferingNewest(0), verbose: Bool = false) {
        self.bufferingPolicy = bufferingPolicy
        self.verbose = verbose
        if verbose { print("🟢 AsyncPublisher init") }
    }
    
    public init(initialValue: Element, bufferingPolicy: BufferingPolicy = .bufferingNewest(1), verbose: Bool = false) {
        self.bufferingPolicy = bufferingPolicy
        self.verbose = verbose
        self.buffer = [initialValue]
        if verbose { print("🟢 AsyncPublisher init with initial value") }
    }
    
    public func stream() -> ElementsStream {
        let id = UUID()
        let (stream, continuation) = ElementsStream.makeStream(bufferingPolicy: .unbounded)
        
        buffer.forEach { continuation.yield($0) }
        subscribers[id] = continuation
        
        if verbose { print("📺 Stream created, total subscribers: \(subscribers.count)") }
        
        continuation.onTermination = { [weak self] termination in
            if self?.verbose == true { print("🔚 Stream terminated: \(termination)") }
            Task { await self?.removeSubscriber(id: id) }
        }
        
        return stream
    }
    
    public func publish(_ value: Element) {
        buffer.append(value)
        applyBufferingPolicy()
        subscribers.values.forEach { $0.yield(value) }
    }
    
    private func applyBufferingPolicy() {
        switch bufferingPolicy {
        case let .bufferingNewest(count):
            if buffer.count > count {
                buffer = Array(buffer.suffix(count))
            }
        case let .bufferingOldest(count):
            if buffer.count > count {
                buffer = Array(buffer.prefix(count))
            }
        case .unbounded:
            break
        @unknown default:
            buffer = []
        }
    }
    
    private func removeSubscriber(id: UUID) {
        subscribers.removeValue(forKey: id)
        if verbose { print("🗑️ Subscriber removed, remaining: \(subscribers.count)") }
    }
    
    deinit {
        if verbose { print("🔴 AsyncPublisher deinit") }
        subscribers.values.forEach { $0.finish() }
    }
}
