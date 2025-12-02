import SwiftUI
import Dependencies

struct GrantVolumeEffectView: View {
    
    // MARK: - State
    
    @State private var topInnerShadowImage: Image?
    @State private var bottomInnerShadowImage: Image?
    @State private var noiseImage: Image?
    
    // MARK: - Dependencies
    
    @Dependency(\.grantsVolumeEffectService) var grantsVolumeEffectService
    
    // MARK: - Private Properties
    
    private let shadowColor: Color
    private let radius: CGFloat
    private let circle: Bool
    private let shouldOptimize: Bool
    private let showParticles: Bool
    
    // MARK: - Init
    
    init(shadowColor: Color, radius: CGFloat, shouldOptimize: Bool = true, showParticles: Bool = true) {
        self.init(
            shadowColor: shadowColor,
            radius: radius,
            circle: false,
            shouldOptimize: shouldOptimize,
            showParticles: showParticles
        )
    }
    
    private init(shadowColor: Color, radius: CGFloat, circle: Bool, shouldOptimize: Bool, showParticles: Bool) {
        self.shadowColor = shadowColor
        self.radius = radius
        self.circle = circle
        self.shouldOptimize = shouldOptimize
        self.showParticles = showParticles
    }
    
    static func circle(shadowColor: Color, shouldOptimize: Bool = true, showParticles: Bool = true) -> Self {
        Self(shadowColor: shadowColor, radius: 0, circle: true, shouldOptimize: shouldOptimize, showParticles: showParticles)
    }
    
    // MARK: - UI
    
    var body: some View {
        GeometryReader { proxy in
            ZStack {
                if showParticles {
                    ShineView(size: proxy.size)
                        .frame(width: proxy.size.width, height: proxy.size.height)
                        /// Needed in reusable elements for complete element recreation
                        .id(UUID())
                }
                
                if shouldOptimize == false {
                    GrantTopWhiteInnerShadow(
                        width: proxy.size.width,
                        height: proxy.size.height,
                        radius: radius,
                        circle: circle
                    )
                    .frame(width: proxy.size.width, height: proxy.size.height)
                    .id("VolumeEffect.GrantTopWhiteInnerShadow")
                    
                } else if let topInnerShadowImage {
                    topInnerShadowImage
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: proxy.size.width, height: proxy.size.height)
                }
                
                if shouldOptimize == false {
                    GrantBottomColorInnerShadow(
                        width: proxy.size.width,
                        height: proxy.size.height,
                        shadowColor: shadowColor,
                        radius: radius,
                        circle: circle
                    )
                    .frame(width: proxy.size.width, height: proxy.size.height)
                    .id("VolumeEffect.GrantBottomColorInnerShadow")
                    
                } else if let bottomInnerShadowImage {
                    bottomInnerShadowImage
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: proxy.size.width, height: proxy.size.height)
                }
            }
            .frame(width: proxy.size.width, height: proxy.size.height)
            .onAppear {
                guard shouldOptimize else {
                    return
                }
                
                updateEffectImages(
                    width: proxy.size.width,
                    height: proxy.size.height,
                    circle: circle
                )
            }
            .onChange(of: proxy.size) { _ in
                guard shouldOptimize else {
                    return
                }
                
                updateEffectImages(
                    width: proxy.size.width,
                    height: proxy.size.height,
                    circle: circle
                )
            }
        }
    }
    
    // MARK: - Private
    
    private func updateEffectImages(
        width: CGFloat,
        height: CGFloat,
        circle: Bool
    ) {
        Task { @MainActor in
            let topImage = await grantsVolumeEffectService.topInnerShadow(
                width: width,
                height: height,
                radius: radius,
                circle: circle
            )
            topInnerShadowImage = topImage.asSUIImage()
            
            let bottomImage = await grantsVolumeEffectService.bottomInnerShadow(
                width: width,
                height: height,
                shadowColor: shadowColor,
                radius: radius,
                circle: circle
            )
            bottomInnerShadowImage = bottomImage.asSUIImage()
            
            let noise = await grantsVolumeEffectService.noiseImage(
                width: width,
                height: height
            )
            noiseImage = noise.asSUIImage()
        }
    }
}

// MARK: - Inner Shadow Components

/// White top inner shadow.
///
/// Method `.shadow(.inner(color:radius:x:y:)`
/// Available only from iOS 16.0.
struct GrantTopWhiteInnerShadow: View {
    
    // MARK: - Private Properties
    
    private let width: CGFloat
    private let height: CGFloat
    private let radius: CGFloat
    private let circle: Bool
    
    // MARK: - Init
    
    init(
        width: CGFloat,
        height: CGFloat,
        radius: CGFloat,
        circle: Bool
    ) {
        self.width = width
        self.height = height
        self.radius = radius
        self.circle = circle
    }
    
    // MARK: - UI
    
    private var rectangleContent: some View {
        RoundedRectangle(cornerRadius: radius)
            .stroke(style: StrokeStyle(lineWidth: 5))
            .fill(Color.inventory.systemWhite.opacity(0.45))
            .blur(radius: 1)
            .offset(y: -0.5)
            .padding(.horizontal, -2)
    }
    
    private var circleContent: some View {
        Circle()
            .stroke(style: StrokeStyle(lineWidth: 5))
            .fill(Color.inventory.systemWhite.opacity(0.45))
            .blur(radius: 1)
            .offset(y: -0.5)
            .padding(.horizontal, -2)
    }
    
    var body: some View {
        ZStack {
            if circle {
                circleContent.clipShape(Circle())
            } else {
                rectangleContent.clipShape(RoundedRectangle(cornerRadius: radius))
            }
        }
        .padding(circle ? 0 : 1)
        .mask(
            LinearGradient(
                colors: [
                    Color.black,
                    Color.black.opacity(0)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
        )
        .frame(width: width, height: height)
    }
}

/// Colored bottom inner shadow.
///
/// Method `.shadow(.inner(color:radius:x:y:)`
/// Available only from iOS 16.0.
struct GrantBottomColorInnerShadow: View {
    
    // MARK: - Private Properties
    
    private let width: CGFloat
    private let height: CGFloat
    private let radius: CGFloat
    private let circle: Bool
    private let shadowColor: Color
    
    // MARK: - Init
    
    init(
        width: CGFloat,
        height: CGFloat,
        shadowColor: Color,
        radius: CGFloat,
        circle: Bool
    ) {
        self.width = width
        self.height = height
        self.shadowColor = shadowColor
        self.radius = radius
        self.circle = circle
    }
    
    // MARK: - UI
    
    private var rectangleContent: some View {
        RoundedRectangle(cornerRadius: radius)
            .stroke(style: StrokeStyle(lineWidth: 8))
            .fill(shadowColor)
            .blur(radius: 1)
            .padding(.horizontal, -2)
    }
    
    private var circleContent: some View {
        Circle()
            .stroke(style: StrokeStyle(lineWidth: 8))
            .fill(shadowColor)
            .blur(radius: 1)
            .padding(.horizontal, -2)
    }
    
    var body: some View {
        ZStack {
            if circle {
                circleContent.clipShape(Circle())
            } else {
                rectangleContent.clipShape(RoundedRectangle(cornerRadius: radius))
            }
        }
        .padding(circle ? -2 : 0)
        .mask(
            LinearGradient(
                colors: [
                    Color.black.opacity(0),
                    Color.black.opacity(0),
                    Color.black
                ],
                startPoint: .top,
                endPoint: .bottom
            )
        )
        .frame(width: width, height: height)
    }
}

// MARK: - Shine Effect

struct ShineView: UIViewRepresentable {
    
    private let size: CGSize
    
    init(size: CGSize) {
        self.size = size
    }
    
    func makeUIView(context: Context) -> ShineUIView {
        ShineUIView(size: size)
    }
    
    func updateUIView(_ uiView: ShineUIView, context: Context) {}
}

final class ShineUIView: UIView {
    
    private struct Constants {
        static let estimatedArea: Float = 40000.0
        static let birthRateForEstimatedArea: Float = 40.0
    }
    
    // MARK: - Private Properties
    
    private let birthRate: Float
    private lazy var emitterLayer = CAEmitterLayer()
    private lazy var emitterCell = CAEmitterCell()
    
    // MARK: - Init
    
    init(size: CGSize) {
        self.birthRate = (Float(size.width * size.height) / Constants.estimatedArea) * Constants.birthRateForEstimatedArea
        super.init(frame: .zero)
        setup()
    }
    
    @available(*, deprecated)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Override
    
    override func layoutSubviews() {
        super.layoutSubviews()
        emitterLayer.emitterPosition = CGPoint(x: bounds.width / 2, y: bounds.height / 2)
        emitterLayer.emitterSize = CGSize(width: bounds.width, height: bounds.height)
    }
    
    func setup() {
        emitterLayer.emitterPosition = CGPoint(x: bounds.width / 2, y: bounds.height / 2)
        emitterLayer.emitterShape = .rectangle
        emitterLayer.emitterSize = CGSize(width: bounds.width, height: bounds.height)
        
        emitterCell.birthRate = birthRate
        emitterCell.lifetime = 7.5
        emitterCell.velocity = 2.2
        emitterCell.velocityRange = 0.25
        emitterCell.emissionRange = .pi * 2
        emitterCell.scale = 0.225
        emitterCell.scaleRange = 0.02
        emitterCell.contents = makeSpeckleImage()?.cgImage
        
        let alphaBehavior = createEmitterBehavior(type: "valueOverLife")
        alphaBehavior.setValue("color.alpha", forKey: "keyPath")
        alphaBehavior.setValue([0, 1, 0], forKey: "values")
        
        emitterLayer.setValue([alphaBehavior], forKey: "emitterBehaviors")
        emitterLayer.emitterCells = [emitterCell]
        
        layer.addSublayer(emitterLayer)
    }
    
    // MARK: - Private
    
    private func makeSpeckleImage() -> UIImage? {
        // Use the original texture asset
        return UIImage(named: "textSpeckle_Light")
    }
}

// MARK: - Helper Functions

func createEmitterBehavior(type: String) -> NSObject {
    let selector = ["behaviorWith", "Type:"].joined(separator: "")
    let behaviorClass = NSClassFromString(["CA", "Emitter", "Behavior"].joined(separator: "")) as! NSObject.Type
    let behaviorWithType = behaviorClass.method(for: NSSelectorFromString(selector))!
    let castedBehaviorWithType = unsafeBitCast(behaviorWithType, to:(@convention(c)(Any?, Selector, Any?) -> NSObject).self)
    return castedBehaviorWithType(behaviorClass, NSSelectorFromString(selector), type)
}

// MARK: - View Snapshot Helper

extension View {
    func snapshot() -> UIImage {
        let controller = UIHostingController(rootView: ignoresSafeArea(.all))
        let view = controller.view
        let targetSize = controller.view.intrinsicContentSize
        view?.bounds = CGRect(origin: .zero, size: targetSize)
        view?.backgroundColor = .clear
        
        let renderer = UIGraphicsImageRenderer(size: targetSize)
        return renderer.image { _ in
            view?.drawHierarchy(in: controller.view.bounds, afterScreenUpdates: true)
        }
    }
}

