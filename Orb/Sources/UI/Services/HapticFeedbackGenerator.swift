import Combine
import Dependencies
import UIKit

protocol HapticFeedbackGenerator: Sendable {
    @MainActor
    func selection()
    @MainActor
    func light(intensity: CGFloat)
    @MainActor
    func medium(intensity: CGFloat)
    @MainActor
    func heavy(intensity: CGFloat)
    @MainActor
    func success()
    @MainActor
    func warning()
    @MainActor
    func error()
}


final class LiveHapticFeedbackGenerator: HapticFeedbackGenerator, Sendable {

    // MARK: - Init
    
    init() {}

    // MARK: - Methods
    
    @MainActor
    func selection() {
        UISelectionFeedbackGenerator().selectionChanged()
    }
    
    @MainActor
    func light(intensity: CGFloat) {
        UIImpactFeedbackGenerator(style: .light).impactOccurred(intensity: intensity)
    }
    
    @MainActor
    func medium(intensity: CGFloat) {
        UIImpactFeedbackGenerator(style: .medium).impactOccurred(intensity: intensity)
    }
    
    @MainActor
    func heavy(intensity: CGFloat) {
        UIImpactFeedbackGenerator(style: .heavy).impactOccurred(intensity: intensity)
    }
    
    @MainActor
    func success() {
        UINotificationFeedbackGenerator().notificationOccurred(.success)
    }
    
    @MainActor
    func warning() {
        UINotificationFeedbackGenerator().notificationOccurred(.warning)
    }
    
    @MainActor
    func error() {
        UINotificationFeedbackGenerator().notificationOccurred(.error)
    }
}

// MARK: - Dependencies

private enum HapticFeedbackGeneratorKey: DependencyKey {
    static let liveValue: HapticFeedbackGenerator = LiveHapticFeedbackGenerator()
    static let testValue: HapticFeedbackGenerator = { fatalError() }()
}

extension DependencyValues {
    var hapticFeedbackGenerator: HapticFeedbackGenerator {
        get { self[HapticFeedbackGeneratorKey.self] }
        set { self[HapticFeedbackGeneratorKey.self] = newValue }
    }
}
