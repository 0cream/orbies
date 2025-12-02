import ComposableArchitecture
import SwiftUI

extension OnboardingFeature {
    @ObservableState
    struct State: Equatable {
        var currentPage: Int = 0
        var totalPages: Int = 3
        var showFirstLine: Bool = false
        var showSecondLine: Bool = false
        var textAnimationCompleted: Bool = false
        var showPageContent: Bool = true
        
        // Page 2 animation state
        var showOrbLogo: Bool = false
        var orbLogoScaled: Bool = false
        var showNotification1: Bool = false
        var showNotification2: Bool = false
        var showNotification3: Bool = false
        var showNotification4: Bool = false
        var showNotification5: Bool = false
        var showNotification6: Bool = false
        var showNotification7: Bool = false
        var showNotification8: Bool = false
        var showNotification9: Bool = false
        var showNotification10: Bool = false
        
        var isLastPage: Bool {
            currentPage == totalPages - 1
        }
    }
}

