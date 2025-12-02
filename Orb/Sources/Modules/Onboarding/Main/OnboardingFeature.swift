import ComposableArchitecture
import Dependencies

@Reducer
struct OnboardingFeature {
    
    // MARK: - Dependencies
    
    @Dependency(\.hapticFeedbackGenerator)
    private var hapticFeedbackGenerator: HapticFeedbackGenerator
    
    // MARK: - Cancel IDs
    
    enum CancelID {
        case animations
    }
    
    // MARK: - Body
    
    var body: some Reducer<State, Action> {
        Reduce { state, action in
            switch action {
            case let .view(action):
                return reduce(state: &state, action: action)
                
            case let .reducer(action):
                return reduce(state: &state, action: action)
                
            case .delegate:
                return .none
            }
        }
    }
    
    // MARK: - View Reducer
    
    private func reduce(state: inout State, action: Action.View) -> Effect<Action> {
        switch action {
        case .didAppear:
            // Cancel any ongoing animations
            let cancelEffect: Effect<Action> = .cancel(id: CancelID.animations)
            
            // Reset all animation state
            state.showFirstLine = false
            state.showSecondLine = false
            state.textAnimationCompleted = false
            state.showPageContent = true // Show content when page appears
            state.showOrbLogo = false
            state.orbLogoScaled = false
            state.showNotification1 = false
            state.showNotification2 = false
            state.showNotification3 = false
            state.showNotification4 = false
            state.showNotification5 = false
            state.showNotification6 = false
            state.showNotification7 = false
            state.showNotification8 = false
            state.showNotification9 = false
            state.showNotification10 = false
            
            if state.currentPage == 1 {
                // Page 2: Text + Orb logo + notifications animation
                return .merge(
                    cancelEffect,
                    .run { send in
                    // Show text first
                    try await Task.sleep(for: .milliseconds(300))
                    await send(.reducer(.showFirstLine))
                    // Show Orb logo simultaneously
                    await send(.reducer(.showOrbLogo))
                    
                    try await Task.sleep(for: .milliseconds(1200))
                    await send(.reducer(.showSecondLine))
                        
                        // Mark text animation as completed
                        try await Task.sleep(for: .milliseconds(300))
                        await send(.reducer(.textAnimationCompleted))
                    
                    // Scale back
                        try await Task.sleep(for: .milliseconds(900))
                    await send(.reducer(.scaleBackOrbLogo))
                    
                    // Show notifications with increasing delays
                    try await Task.sleep(for: .milliseconds(300))
                    await send(.reducer(.showNotification1))
                    
                    try await Task.sleep(for: .milliseconds(100))
                    await send(.reducer(.showNotification2))
                    
                    try await Task.sleep(for: .milliseconds(100))
                    await send(.reducer(.showNotification3))
                    
                    try await Task.sleep(for: .milliseconds(200))
                    await send(.reducer(.showNotification4))
                    
                    try await Task.sleep(for: .milliseconds(300))
                    await send(.reducer(.showNotification5))
                    
                    try await Task.sleep(for: .milliseconds(800))
                    await send(.reducer(.showNotification6))
                    
                    try await Task.sleep(for: .milliseconds(900))
                    await send(.reducer(.showNotification7))
                    
                    try await Task.sleep(for: .milliseconds(1000))
                    await send(.reducer(.showNotification8))
                    
                    try await Task.sleep(for: .milliseconds(1100))
                    await send(.reducer(.showNotification9))
                    
                    try await Task.sleep(for: .milliseconds(1200))
                    await send(.reducer(.showNotification10))
                }
                    .cancellable(id: CancelID.animations)
                )
            } else {
                // Other pages: Text animation sequence
                return .merge(
                    cancelEffect,
                    .run { send in
                        // Wait a bit longer before showing first line for smoother transition
                    try await Task.sleep(for: .milliseconds(300))
                    await send(.reducer(.showFirstLine))
                    
                        // Show second line after another 1200ms
                    try await Task.sleep(for: .milliseconds(1200))
                    await send(.reducer(.showSecondLine))
                        
                        // Mark text animation as completed after 300ms
                        try await Task.sleep(for: .milliseconds(300))
                        await send(.reducer(.textAnimationCompleted))
                }
                    .cancellable(id: CancelID.animations)
                )
            }
            
        case .didTapNext:
            if state.isLastPage {
                // Complete onboarding
                return .merge(
                    .run { _ in await hapticFeedbackGenerator.light(intensity: 1.0) },
                    .send(.delegate(.didComplete))
                )
            } else {
                // Hide ALL content FIRST (text + page content)
                state.showFirstLine = false
                state.showSecondLine = false
                state.showPageContent = false
                state.textAnimationCompleted = false
                
                // Wait for fade out animation to complete, THEN change page
                return .run { [currentPage = state.currentPage] send in
                    await hapticFeedbackGenerator.light(intensity: 1.0)
                    
                    // Wait for content to fade out (300ms animation)
                    try await Task.sleep(for: .milliseconds(300))
                    
                    // Now change page
                    await send(.reducer(.changePage(currentPage + 1)))
                }
            }
            
        case .didTapSkip:
            // Skip to end
            return .merge(
                .run { _ in await hapticFeedbackGenerator.light(intensity: 1.0) },
                .send(.delegate(.didComplete))
            )
        }
    }
    
    // MARK: - Reducer
    
    private func reduce(state: inout State, action: Action.Reducer) -> Effect<Action> {
        switch action {
        case .showFirstLine:
            state.showFirstLine = true
            return .run { _ in
                await hapticFeedbackGenerator.light(intensity: 0.8)
            }
            
        case .showSecondLine:
            state.showSecondLine = true
            return .run { _ in
                await hapticFeedbackGenerator.light(intensity: 0.8)
            }
            
        case .textAnimationCompleted:
            state.textAnimationCompleted = true
            return .none
            
        case let .changePage(page):
            state.currentPage = page
            // Trigger animation for new page
            return .send(.view(.didAppear))
            
        case .showOrbLogo:
            state.showOrbLogo = true
            return .run { _ in
                await hapticFeedbackGenerator.medium(intensity: 1.0)
            }
            
        case .scaleBackOrbLogo:
            state.orbLogoScaled = true
            return .run { _ in
                await hapticFeedbackGenerator.light(intensity: 0.6)
            }
            
        case .showNotification1:
            state.showNotification1 = true
            return .run { _ in
                await hapticFeedbackGenerator.light(intensity: 0.8)
            }
            
        case .showNotification2:
            state.showNotification2 = true
            return .run { _ in
                await hapticFeedbackGenerator.light(intensity: 0.8)
            }
            
        case .showNotification3:
            state.showNotification3 = true
            return .run { _ in
                await hapticFeedbackGenerator.light(intensity: 0.8)
            }
            
        case .showNotification4:
            state.showNotification4 = true
            return .run { _ in
                await hapticFeedbackGenerator.light(intensity: 0.8)
            }
            
        case .showNotification5:
            state.showNotification5 = true
            return .run { _ in
                await hapticFeedbackGenerator.light(intensity: 0.8)
            }
            
        case .showNotification6:
            state.showNotification6 = true
            return .run { _ in
                await hapticFeedbackGenerator.light(intensity: 0.8)
            }
            
        case .showNotification7:
            state.showNotification7 = true
            return .run { _ in
                await hapticFeedbackGenerator.light(intensity: 0.8)
            }
            
        case .showNotification8:
            state.showNotification8 = true
            return .run { _ in
                await hapticFeedbackGenerator.light(intensity: 0.8)
            }
            
        case .showNotification9:
            state.showNotification9 = true
            return .run { _ in
                await hapticFeedbackGenerator.light(intensity: 0.8)
            }
            
        case .showNotification10:
            state.showNotification10 = true
            return .run { _ in
                await hapticFeedbackGenerator.light(intensity: 0.8)
            }
        }
    }
}
