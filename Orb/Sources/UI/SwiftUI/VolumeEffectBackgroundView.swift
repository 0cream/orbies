import SwiftUI

struct VolumeEffectBackgroundView: View {
    
    // MARK: - Private Properties
    
    private let configuration: VolumeEffectBackgroundViewConfiguration
    
    // MARK: - Init
    
    init(configuration: VolumeEffectBackgroundViewConfiguration) {
        self.configuration = configuration
    }
    
    // MARK: - UI
    
    var body: some View {
        GeometryReader { proxy in
            ZStack {
                LinearGradient(
                    colors: [
                        configuration.style.startColor,
                        configuration.style.endColor
                    ],
                    startPoint: configuration.style.startPoint,
                    endPoint: configuration.style.endPoint
                )
                
                let id = [
                    "VolumeEffectBackgroundView",
                    "\(configuration.size.cornerRadius)",
                    "\(proxy.size.width)",
                    "\(proxy.size.height)"
                ]
                
                let cornerRadius = configuration.size.capsule
                    ? proxy.size.height / 2
                    : vw(x: configuration.size.cornerRadius)
                
                GrantVolumeEffectView(
                    shadowColor: configuration.style.bottomShadowColor,
                    radius: cornerRadius - 1,
                    shouldOptimize: configuration.shouldOptimize,
                    showParticles: configuration.showParticles
                )
                .frame(width: proxy.size.width, height: proxy.size.height)
                .id(id.joined(separator: "."))
            }
        }
        .if(configuration.size.capsule == true) { view in
            view.clipShape(Capsule())
        }
        .if(configuration.size.capsule == false) { view in
            view.clipShape(RoundedRectangle(cornerRadius: vw(x: configuration.size.cornerRadius)))
        }
    }
}

// MARK: - Configuration

struct VolumeEffectBackgroundViewConfiguration: Equatable, Sendable {
    
    // MARK: - Properties
    
    let style: VolumeEffectBackgroundStyle
    let size: VolumeEffectBackgroundSize
    /// If value is `true` volume effect view will use internal render mechanism to draw lights and shadows for better performance.
    /// If value is `false` volume effect view will use default SwiftUI render mechanism,
    let shouldOptimize: Bool
    /// If value is `true`, sparkle particles will be rendered
    /// If value is `false`, no particles will be shown (only shadows)
    let showParticles: Bool
    
    // MARK: - Static
    
    static func blue(size: VolumeEffectBackgroundSize, shouldOptimize: Bool = true, showParticles: Bool = true) -> Self {
        Self(
            style: VolumeEffectBackgroundStyle(
                startColor: Color(rgb: 0x19C1FE),
                startPoint: UnitPoint(x: 0, y: 0),
                endColor: Color(rgb: 0x472BFC),
                endPoint: UnitPoint(x: 1, y: 1),
                bottomShadowColor: Color.inventory.systemBlack.opacity(0.15)
            ),
            size: size,
            shouldOptimize: shouldOptimize,
            showParticles: showParticles
        )
    }
    
    static func purple(size: VolumeEffectBackgroundSize, shouldOptimize: Bool = true, showParticles: Bool = true) -> Self {
        Self(
            style: VolumeEffectBackgroundStyle(
                topColor: Color(rgb: 0x6C24E8),
                bottomColor: Color(rgb: 0x2C35BC),
                bottomShadowColor: Color.inventory.systemBlack.opacity(0.15)
            ),
            size: size,
            shouldOptimize: shouldOptimize,
            showParticles: showParticles
        )
    }
    
    static func orange(size: VolumeEffectBackgroundSize, shouldOptimize: Bool = true, showParticles: Bool = true) -> Self {
        Self(
            style: VolumeEffectBackgroundStyle(
                topColor: Color(red: 1.0, green: 0.35, blue: 0.2),
                bottomColor: Color(red: 1.0, green: 0.25, blue: 0.2),
                bottomShadowColor: Color.inventory.systemBlack.opacity(0.15)),
            size: size,
            shouldOptimize: shouldOptimize,
            showParticles: showParticles
        )
    }
    
    static func green(size: VolumeEffectBackgroundSize, shouldOptimize: Bool = true, showParticles: Bool = true) -> Self {
        Self(
            style: VolumeEffectBackgroundStyle(
                topColor: Color(rgb: 0x05B04D),
                bottomColor: Color(rgb: 0x23CE6B),
                bottomShadowColor: Color.inventory.systemBlack.opacity(0.15)),
            size: size,
            shouldOptimize: shouldOptimize,
            showParticles: showParticles
        )
    }
    
    static func black(size: VolumeEffectBackgroundSize, shouldOptimize: Bool = true, showParticles: Bool = true) -> Self {
        Self(
            style: VolumeEffectBackgroundStyle(
                topColor: Color(rgb: 0x2C2C2E),
                bottomColor: Color(rgb: 0x1C1C1E),
                bottomShadowColor: Color.inventory.systemBlack.opacity(0.5)
            ),
            size: size,
            shouldOptimize: shouldOptimize,
            showParticles: showParticles
        )
    }
    
    // MARK: - CS:GO Rarity Colors
    
    static func csgoRare(size: VolumeEffectBackgroundSize, shouldOptimize: Bool = true, showParticles: Bool = true) -> Self {
        Self(
            style: VolumeEffectBackgroundStyle(
                topColor: Color(rgb: 0x5C7AFF),
                bottomColor: Color(rgb: 0x3855D9),
                bottomShadowColor: Color.inventory.systemBlack.opacity(0.3)
            ),
            size: size,
            shouldOptimize: shouldOptimize,
            showParticles: showParticles
        )
    }
    
    static func csgoCovert(size: VolumeEffectBackgroundSize, shouldOptimize: Bool = true, showParticles: Bool = true) -> Self {
        Self(
            style: VolumeEffectBackgroundStyle(
                topColor: Color(rgb: 0x8B5CF6),
                bottomColor: Color(rgb: 0x6E3AD4),
                bottomShadowColor: Color.inventory.systemBlack.opacity(0.3)
            ),
            size: size,
            shouldOptimize: shouldOptimize,
            showParticles: showParticles
        )
    }
    
    static func csgoGold(size: VolumeEffectBackgroundSize, shouldOptimize: Bool = true, showParticles: Bool = true) -> Self {
        Self(
            style: VolumeEffectBackgroundStyle(
                topColor: Color(rgb: 0xE961FA),
                bottomColor: Color(rgb: 0xD32CE6),
                bottomShadowColor: Color.inventory.systemBlack.opacity(0.3)
            ),
            size: size,
            shouldOptimize: shouldOptimize,
            showParticles: showParticles
        )
    }
    
    static func csgoComplete(size: VolumeEffectBackgroundSize, shouldOptimize: Bool = true, showParticles: Bool = true) -> Self {
        Self(
            style: VolumeEffectBackgroundStyle(
                topColor: Color(rgb: 0x2C2C2E),
                bottomColor: Color(rgb: 0x1C1C1E),
                bottomShadowColor: Color.inventory.systemBlack.opacity(0.5)
            ),
            size: size,
            shouldOptimize: shouldOptimize,
            showParticles: showParticles
        )
    }
}

struct VolumeEffectBackgroundSize: Equatable, Sendable {
    let cornerRadius: CGFloat
    let capsule: Bool
    
    init(cornerRadius: CGFloat) {
        self.init(cornerRadius: cornerRadius, capsule: false)
    }
    
    private init(cornerRadius: CGFloat, capsule: Bool) {
        self.cornerRadius = cornerRadius
        self.capsule = capsule
    }
    
    static let capsule = Self(cornerRadius: 0, capsule: true)
}

struct VolumeEffectBackgroundStyle: Equatable, Sendable {
    
    let startColor: Color
    let startPoint: UnitPoint
    let endColor: Color
    let endPoint: UnitPoint
    let bottomShadowColor: Color
    
    init(
        startColor: Color,
        startPoint: UnitPoint,
        endColor: Color,
        endPoint: UnitPoint,
        bottomShadowColor: Color
    ) {
        self.startColor = startColor
        self.startPoint = startPoint
        self.endColor = endColor
        self.endPoint = endPoint
        self.bottomShadowColor = bottomShadowColor
    }
    
    init(topColor: Color, bottomColor: Color, bottomShadowColor: Color) {
        self.init(
            startColor: topColor,
            startPoint: .top,
            endColor: bottomColor,
            endPoint: .bottom,
            bottomShadowColor: bottomShadowColor
        )
    }
}

