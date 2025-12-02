import Foundation

struct Command: Equatable, Hashable, Sendable {
    let id: String
    private let action: @Sendable () async -> Void

    // MARK: - Init

    init(
        id: String = UUID().uuidString,
        action: @escaping @Sendable () async -> Void
    ) {
        self.id = id
        self.action = action
    }

    func run() {
        Task {
            await runAsync()
        }
    }
    
    func runAsync() async {
        await action()
    }

    // MARK: - Equatable

    static func == (lhs: Command, rhs: Command) -> Bool {
        lhs.id == rhs.id
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    // MARK: - Static

    static let none = Command(id: "none", action: {})
}

struct GenericCommand<T>: Equatable {
    let id: String
    private let action: (T) -> Void

    // MARK: - Init

    init(
        id: String = UUID().uuidString,
        action: @escaping (T) -> Void
    ) {
        self.id = id
        self.action = action
    }

    func run(with value: T) {
        action(value)
    }

    // MARK: - Equatable

    static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.id == rhs.id
    }
}
