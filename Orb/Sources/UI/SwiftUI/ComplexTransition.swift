import SwiftUI

extension AnyTransition {
    @MainActor
    static func single(
        x: CGFloat = .zero,
        y: CGFloat = .zero,
        blur: CGFloat? = nil,
        angle: Angle = .degrees(.zero),
        scale: CGFloat = 1,
        scaleAnchor: UnitPoint = .center,
        opacity: CGFloat = 1,
        animation: Animation
    ) -> AnyTransition {

        .modifier(
            active: ComplexTransitionModifier(
                x: x,
                y: y,
                blur: blur,
                angle: angle,
                opacity: opacity,
                scale: scale,
                scaleAnchor: scaleAnchor,
                animation: animation
            ),
            identity: ComplexTransitionModifier.identity(
                isBlurEnabled: blur != nil,
                animation: animation
            )
        )
    }
    
    @MainActor
    static func complex(
        x: CGFloat = .zero,
        y: CGFloat = .zero,
        blur: CGFloat? = nil,
        angle: Angle = .degrees(.zero),
        scale: CGFloat = 1,
        scaleAnchor: UnitPoint = .center,
        opacity: CGFloat = 1,
        insertionDelay: CGFloat = .zero,
        removalDelay: CGFloat = .zero,
        animation: Animation
    ) -> AnyTransition {
        
        .asymmetric(
            insertion: .single(
                x: x,
                y: y,
                blur: blur,
                angle: angle,
                scale: scale,
                scaleAnchor: scaleAnchor,
                opacity: opacity,
                animation: insertionDelay > 0 ? animation.delay(insertionDelay) : animation
            ),
            removal: .single(
                x: x,
                y: y,
                blur: blur,
                angle: angle,
                scale: scale,
                scaleAnchor: scaleAnchor,
                opacity: opacity,
                animation: removalDelay > 0 ? animation.delay(removalDelay) : animation
            )
        )
    }
}

extension AnyTransition {
    @MainActor
    static func blurReplacement(insertionDelay: TimeInterval = 0.15, scale: CGFloat = 0.8) -> AnyTransition {
        .complex(
            blur: 4,
            scale: scale,
            opacity: 0,
            insertionDelay: insertionDelay,
            animation: .easeOut(duration: 0.15)
        )
    }
    
    @MainActor
    static func opacityReplacement(blur: CGFloat? = nil) -> AnyTransition {
        .complex(
            blur: blur,
            opacity: 0,
            insertionDelay: 0,
            animation: .easeOut(duration: 0.15)
        )
    }
}

struct ComplexTransitionModifier: ViewModifier {
    let offset: CGSize
    let blur: CGFloat?
    let angle: Angle
    let opacity: CGFloat
    let scale: CGFloat
    let scaleAnchor: UnitPoint
    let animation: Animation?

    // MARK: - Init

    init(
        offset: CGSize,
        blur: CGFloat? = nil,
        angle: Angle = .degrees(.zero),
        opacity: CGFloat,
        scale: CGFloat,
        scaleAnchor: UnitPoint,
        animation: Animation? = nil
    ) {
        self.offset = offset
        self.blur = blur
        self.angle = angle
        self.scale = scale
        self.scaleAnchor = scaleAnchor
        self.opacity = opacity
        self.animation = animation
    }

    init(
        x: CGFloat = .zero,
        y: CGFloat = .zero,
        blur: CGFloat? = nil,
        angle: Angle = .degrees(.zero),
        opacity: CGFloat,
        scale: CGFloat,
        scaleAnchor: UnitPoint,
        animation: Animation? = nil
    ) {
        self.offset = CGSize(width: x, height: y)
        self.blur = blur
        self.angle = angle
        self.scale = scale
        self.scaleAnchor = scaleAnchor
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
            .scaleEffect(scale, anchor: scaleAnchor)
            .animation(animation, value: scale)
            .offset(offset)
            .animation(animation, value: offset)
            .rotationEffect(angle)
            .animation(animation, value: angle)
    }

    static func identity(isBlurEnabled: Bool, animation: Animation? = nil) -> Self {
        Self(
            offset: .zero,
            blur: isBlurEnabled ? .zero : nil,
            opacity: 1,
            scale: 1,
            scaleAnchor: .center,
            animation: animation
        )
    }
}
