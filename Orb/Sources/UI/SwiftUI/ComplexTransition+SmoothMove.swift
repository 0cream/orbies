import SwiftUI

extension AnyTransition {
    static func smoothMove(
        x: CGFloat = .zero,
        y: CGFloat = .zero,
        blur: CGFloat? = nil,
        scale: CGFloat = 1,
        opacity: CGFloat = 1,
        animation: Animation
    ) -> AnyTransition {
        .modifier(
            active: MoveTransitionModifier(
                x: x,
                y: y,
                blur: blur,
                opacity: opacity,
                scale: scale,
                animation: animation
            ),
            identity: MoveTransitionModifier.identity(
                isBlurEnabled: blur != nil,
                animation: animation
            )
        )
    }
}

struct MoveTransitionModifier: ViewModifier {
    let offset: CGSize
    let blur: CGFloat?
    let opacity: CGFloat
    let scale: CGFloat
    let animation: Animation?
    
    // MARK: - Init
    
    init(
        offset: CGSize,
        blur: CGFloat? = nil,
        opacity: CGFloat,
        scale: CGFloat,
        animation: Animation? = nil
    ) {
        self.offset = offset
        self.blur = blur
        self.scale = scale
        self.opacity = opacity
        self.animation = animation
    }
    
    init(
        x: CGFloat = .zero,
        y: CGFloat = .zero,
        blur: CGFloat? = nil,
        opacity: CGFloat,
        scale: CGFloat,
        animation: Animation? = nil
    ) {
        self.offset = CGSize(width: x, height: y)
        self.blur = blur
        self.scale = scale
        self.opacity = opacity
        self.animation = animation
    }
    
    func body(content: Content) -> some View {
        content
            .opacity(opacity)
            .animation(animation, value: opacity)
            .if_let(blur) { view, blur in
                view
                    .blur(radius: blur)
                    .animation(animation, value: blur)
            }
            .scaleEffect(scale)
            .animation(animation, value: scale)
            .offset(offset)
            .animation(animation, value: offset)
    }
    
    static func identity(isBlurEnabled: Bool, animation: Animation? = nil) -> Self {
        Self(
            offset: .zero,
            blur: isBlurEnabled ? .zero : nil,
            opacity: 1,
            scale: 1,
            animation: animation
        )
    }
}

