import Combine
import Dependencies
import UIKit

protocol SmartPressFeedbackGenerator: Sendable {
    @MainActor
    func press()
    @MainActor
    func release(force: Bool)
    @MainActor
    func release()
}

@MainActor
final class LiveSmartPressFeedbackGenerator: SmartPressFeedbackGenerator {

    // MARK: - Constants

    private let onPressStyle: UIImpactFeedbackGenerator.FeedbackStyle
    private let onReleaseStyle: UIImpactFeedbackGenerator.FeedbackStyle

    // MARK: - Private Properties

    private var shouldRelease = false
    
    // MARK: - Combine
    
    private let pressSubject = PassthroughSubject<Bool, Never>()
    private var cancellables = Set<AnyCancellable>()

    // MARK: - Init

    init(
        onPressStyle: UIImpactFeedbackGenerator.FeedbackStyle = .soft,
        onReleaseStyle: UIImpactFeedbackGenerator.FeedbackStyle = .light
    ) {
        self.onPressStyle = onPressStyle
        self.onReleaseStyle = onReleaseStyle

        pressSubject
            .debounce(for: .milliseconds(100), scheduler: DispatchQueue.main)
            .sink { [weak self] value in
                Task { @MainActor [weak self] in
                    self?.shouldRelease = value
                }
            }
            .store(in: &cancellables)
    }

    // MARK: - Methods

    func press() {
        pressSubject.send(true)

        UIImpactFeedbackGenerator(style: onPressStyle).impactOccurred()
    }
    
    func release() {
        release(force: false)
    }

    func release(force: Bool) {
        if shouldRelease || force {
            UIImpactFeedbackGenerator(style: onReleaseStyle).impactOccurred()
        }

        pressSubject.send(false)
        shouldRelease = false
    }
}

private enum SmartPressFeedbackGeneratorKey: DependencyKey {
    static let liveValue: SmartPressFeedbackGenerator = {
        MainActor.assumeIsolated {
            LiveSmartPressFeedbackGenerator()
        }
    }()
    
    static let testValue: SmartPressFeedbackGenerator = { fatalError() }()
}

extension DependencyValues {
    var smartPressFeedbackGenerator: SmartPressFeedbackGenerator {
        get { self[SmartPressFeedbackGeneratorKey.self] }
        set { self[SmartPressFeedbackGeneratorKey.self] = newValue }
    }
}
