import SwiftUI

struct ResponsiveButtonStyle: ButtonStyle {
    
    // MARK: - Private Properties
    
    private let configuration: ResponsiveButtonStyleConfiguration
    
    // MARK: - Init
    
    init(configuration: ResponsiveButtonStyleConfiguration) {
        self.configuration = configuration
    }
    
    // MARK: - ButtonStyle
    
    func makeBody(configuration: Configuration) -> some View {
        return configuration.label
            .haptic(isPressed: configuration.isPressed)
            .if_let(self.configuration.opacity) { view, _ in
                let opacity = configuration.isPressed ? self.configuration.opacity ?? 1 : 1
                
                view
                    .opacity(opacity)
                    .animation(self.configuration.animation, value: opacity)
            }
            .if_let(self.configuration.scale) { view, _ in
                let scale = configuration.isPressed ? self.configuration.scale ?? 1 : 1
                
                view
                    .scaleEffect(scale)
                    .animation(self.configuration.animation, value: scale)
            }
    }
}

// MARK: - Helpers

struct ResponsiveButtonStyleConfiguration {
    let opacity: CGFloat?
    let scale: CGFloat?
    let animation: Animation
    
    static let `default` = Self(
        opacity: 0.75,
        scale: nil,
        animation: .easeOut(duration: 0.1)
    )
    
    static let scale = Self(
        opacity: 0.75,
        scale: 0.95,
        animation: .easeOut(duration: 0.1)
    )
}

// MARK: - Extension

extension ButtonStyle where Self == ResponsiveButtonStyle {
    static func responsive(_ configuration: ResponsiveButtonStyleConfiguration) -> Self {
        ResponsiveButtonStyle(configuration: configuration)
    }
}
