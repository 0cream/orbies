import ComposableArchitecture

extension Effect {
    static func runErrorHaptic() -> Effect<Action> {
        .run { _ in
            @Dependency(\.hapticFeedbackGenerator)
            var hapticFeedbackGenerator: HapticFeedbackGenerator
            await hapticFeedbackGenerator.error()
        }
    }
    
    static func runWarningHaptic() -> Effect<Action> {
        .run { _ in
            @Dependency(\.hapticFeedbackGenerator)
            var hapticFeedbackGenerator: HapticFeedbackGenerator
            await hapticFeedbackGenerator.warning()
        }
    }
    
    static func runSuccessHaptic() -> Effect<Action> {
        .run { _ in
            @Dependency(\.hapticFeedbackGenerator)
            var hapticFeedbackGenerator: HapticFeedbackGenerator
            await hapticFeedbackGenerator.success()
        }
    }
}
