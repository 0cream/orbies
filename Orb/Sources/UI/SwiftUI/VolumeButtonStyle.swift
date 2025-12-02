import SwiftUI

struct VolumeButtonStyle: ButtonStyle {
    
    // MARK: - Private Properties
    
    private let configuration: VolumeButtonConfiguration
    
    // MARK: - Helpers
    
    func scaleEffect(configuration: Configuration) -> CGFloat {
        configuration.isPressed ? self.configuration.scaleFactor : 1
    }
    
    // MARK: - Init
    
    init(configuration: VolumeButtonConfiguration) {
        self.configuration = configuration
    }
    
    // MARK: - Methods
    
    func makeBody(configuration: Configuration) -> some View {
        let content = configuration.label
            .font(self.configuration.size.font)
            .foregroundStyle(Color.inventory.systemWhite)
            .shadow(color: Color.inventory.systemBlack.opacity(0.75), radius: 8, y: 2)
        
        return content
            .opacity(0)
            .frame(
                minWidth: self.configuration.size.minWidth,
                maxWidth: self.configuration.size.maxWidth,
                minHeight: self.configuration.size.minHeight,
                maxHeight: self.configuration.size.maxHeight,
                alignment: .center
            )
            .background(
                VolumeEffectBackgroundView(configuration: self.configuration.volumeEffect)
            )
            .overlay {
                content
            }
            .haptic(isPressed: configuration.isPressed)
            .scaleEffect(scaleEffect(configuration: configuration))
            .animation(.easeOut(duration: 0.1), value: scaleEffect(configuration: configuration))
    }
}

// MARK: - Configuration

struct VolumeButtonConfiguration: Equatable, Sendable {
    
    // MARK: - Properties
    
    let volumeEffect: VolumeEffectBackgroundViewConfiguration
    let size: VolumeButtonSize
    let scaleFactor: CGFloat
    
    // MARK: - Init
    
    init(
        volumeEffect: VolumeEffectBackgroundViewConfiguration,
        size: VolumeButtonSize,
        scaleFactor: CGFloat = 0.975
    ) {
        self.volumeEffect = volumeEffect
        self.size = size
        self.scaleFactor = scaleFactor
    }
    
    // MARK: - Static
    
    static let largeBlue = Self(
        volumeEffect: .blue(size: VolumeEffectBackgroundSize(cornerRadius: 24)),
        size: VolumeButtonSize(
            font: .system(size: 20, weight: .semibold),
            maxWidth: .infinity,
            minHeight: 72,
            maxHeight: 72
        )
    )
    
    static let largePurple = Self(
        volumeEffect: .purple(size: VolumeEffectBackgroundSize(cornerRadius: 24)),
        size: VolumeButtonSize(
            font: .system(size: 20, weight: .semibold),
            maxWidth: .infinity,
            minHeight: 72,
            maxHeight: 72
        )
    )
    
    static let largeGreen = Self(
        volumeEffect: .green(size: VolumeEffectBackgroundSize(cornerRadius: 24)),
        size: VolumeButtonSize(
            font: .system(size: 20, weight: .semibold),
            maxWidth: .infinity,
            minHeight: 72,
            maxHeight: 72
        )
    )
    
    static let largeBlack = Self(
        volumeEffect: .black(size: VolumeEffectBackgroundSize(cornerRadius: 24)),
        size: VolumeButtonSize(
            font: .system(size: 20, weight: .semibold),
            maxWidth: .infinity,
            minHeight: 72,
            maxHeight: 72
        )
    )
    
    static let largeOrange = Self(
        volumeEffect: .orange(size: VolumeEffectBackgroundSize(cornerRadius: 24)),
        size: VolumeButtonSize(
            font: .system(size: 20, weight: .semibold),
            maxWidth: .infinity,
            minHeight: 72,
            maxHeight: 72
        )
    )
    
    static let smallPurple = Self(
        volumeEffect: .purple(size: VolumeEffectBackgroundSize(cornerRadius: 21), shouldOptimize: false),
        size: VolumeButtonSize(
            font: .system(size: 16, weight: .semibold),
            minHeight: 42,
            maxHeight: 42
        )
    )
    
    static let smallOrange = Self(
        volumeEffect: .orange(size: VolumeEffectBackgroundSize(cornerRadius: 21), shouldOptimize: false),
        size: VolumeButtonSize(
            font: .system(size: 16, weight: .semibold),
            minHeight: 42,
            maxHeight: 42
        )
    )
    
    static let smallGreen = Self(
        volumeEffect: .green(size: VolumeEffectBackgroundSize(cornerRadius: 21), shouldOptimize: false),
        size: VolumeButtonSize(
            font: .system(size: 16, weight: .semibold),
            minHeight: 42,
            maxHeight: 42
        )
    )
    
    static let smallBlack = Self(
        volumeEffect: .black(size: VolumeEffectBackgroundSize(cornerRadius: 21), shouldOptimize: false),
        size: VolumeButtonSize(
            font: .system(size: 16, weight: .semibold),
            minHeight: 42,
            maxHeight: 42
        )
    )
    
    static let banner = Self(
        volumeEffect: .black(size: VolumeEffectBackgroundSize(cornerRadius: 32)),
        size: VolumeButtonSize(
            font: .system(size: 20, weight: .semibold),
            maxWidth: .infinity,
            minHeight: 160
        ),
        scaleFactor: 0.98
    )
    
    static let bannerRare = Self(
        volumeEffect: .csgoRare(size: VolumeEffectBackgroundSize(cornerRadius: 32)),
        size: VolumeButtonSize(
            font: .system(size: 20, weight: .semibold),
            maxWidth: .infinity,
            minHeight: 160
        ),
        scaleFactor: 0.98
    )
    
    static let bannerCovert = Self(
        volumeEffect: .csgoCovert(size: VolumeEffectBackgroundSize(cornerRadius: 32)),
        size: VolumeButtonSize(
            font: .system(size: 20, weight: .semibold),
            maxWidth: .infinity,
            minHeight: 160
        ),
        scaleFactor: 0.98
    )
    
    static let bannerGold = Self(
        volumeEffect: .csgoGold(size: VolumeEffectBackgroundSize(cornerRadius: 32)),
        size: VolumeButtonSize(
            font: .system(size: 20, weight: .semibold),
            maxWidth: .infinity,
            minHeight: 160
        ),
        scaleFactor: 0.98
    )
    
    static let bannerComplete = Self(
        volumeEffect: .csgoComplete(size: VolumeEffectBackgroundSize(cornerRadius: 32)),
        size: VolumeButtonSize(
            font: .system(size: 20, weight: .semibold),
            maxWidth: .infinity,
            minHeight: 160
        ),
        scaleFactor: 0.98
    )
}

struct VolumeButtonSize: Equatable, Sendable {
    let font: Font
    let minWidth: CGFloat?
    let maxWidth: CGFloat?
    let minHeight: CGFloat?
    let maxHeight: CGFloat?
    
    init(
        font: Font,
        minWidth: CGFloat? = nil,
        maxWidth: CGFloat? = nil,
        minHeight: CGFloat? = nil,
        maxHeight: CGFloat? = nil
    ) {
        self.font = font
        self.minWidth = minWidth
        self.maxWidth = maxWidth
        self.minHeight = minHeight
        self.maxHeight = maxHeight
    }
}

// MARK: - ButtonStyle Extension

extension ButtonStyle where Self == VolumeButtonStyle {
    static func volume(_ configuration: VolumeButtonConfiguration) -> Self {
        VolumeButtonStyle(configuration: configuration)
    }
    
    static var volumeLargeBlue: Self {
        VolumeButtonStyle(configuration: .largeBlue)
    }
    
    static var volumeLargePurple: Self {
        VolumeButtonStyle(configuration: .largePurple)
    }
    
    static var volumeLargeGreen: Self {
        VolumeButtonStyle(configuration: .largeGreen)
    }
    
    static var volumeLargeBlack: Self {
        VolumeButtonStyle(configuration: .largeBlack)
    }
    
    static var volumeLargeOrange: Self {
        VolumeButtonStyle(configuration: .largeOrange)
    }
    
    static var volumeSmallPurple: Self {
        VolumeButtonStyle(configuration: .smallPurple)
    }
    
    static var volumeSmallOrange: Self {
        VolumeButtonStyle(configuration: .smallOrange)
    }
    
    static var volumeSmallGreen: Self {
        VolumeButtonStyle(configuration: .smallGreen)
    }
    
    static var volumeSmallBlack: Self {
        VolumeButtonStyle(configuration: .smallBlack)
    }
    
    static var volumeBanner: Self {
        VolumeButtonStyle(configuration: .banner)
    }
}

