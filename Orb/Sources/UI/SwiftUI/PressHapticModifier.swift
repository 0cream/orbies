import Dependencies
import SwiftUI

struct PressHapticModifier: ViewModifier {

    // MARK: - Private Properties

    @Dependency(\.smartPressFeedbackGenerator)
    private var smartPressFeedbackGenerator: SmartPressFeedbackGenerator

    private let trigger: Bool
    private let release: Bool
    private let press: Bool

    // MARK: - Init

    init(trigger: Bool, release: Bool = true, press: Bool = true) {
        self.trigger = trigger
        self.release = release
        self.press = press
    }

    // MARK: - ViewModifier

    func body(content: Content) -> some View {
        content
            .onChange(of: trigger) { _, newValue in
                newValue
                    ? press ? smartPressFeedbackGenerator.press() : (())
                    : release ? smartPressFeedbackGenerator.release() : (())
            }
    }
}

extension View {
    func haptic(isPressed: Bool) -> some View {
        self.modifier(PressHapticModifier(trigger: isPressed))
    }
}
