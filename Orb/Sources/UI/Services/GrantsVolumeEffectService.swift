import Dependencies
import SwiftUI

protocol GrantsVolumeEffectService: Sendable {
    @MainActor
    func topInnerShadow(
        width: CGFloat,
        height: CGFloat,
        radius: CGFloat,
        circle: Bool
    ) async -> UIImage
    
    @MainActor
    func bottomInnerShadow(
        width: CGFloat,
        height: CGFloat,
        shadowColor: Color,
        radius: CGFloat,
        circle: Bool
    ) async -> UIImage
    
    @MainActor
    func noiseImage(
        width: CGFloat,
        height: CGFloat
    ) async -> UIImage
}

final class LiveGrantsVolumeEffectService: GrantsVolumeEffectService, Sendable {
    
    private struct BottomInnerShadowKey: Hashable {
        let width: CGFloat
        let height: CGFloat
        let shadowColor: Color
        let radius: CGFloat
        let circle: Bool
    }
    
    private struct TopInnerShadowKey: Hashable {
        let width: CGFloat
        let height: CGFloat
        let radius: CGFloat
        let circle: Bool
    }
    
    private struct NoiseImageKey: Hashable {
        let width: CGFloat
        let height: CGFloat
    }
    
    // MARK: - Private Properties
    
    private let noiseImageCache = Cache<NoiseImageKey, UIImage>()
    private let topInnerShadowCache = Cache<TopInnerShadowKey, UIImage>()
    private let bottomInnerShadowCache = Cache<BottomInnerShadowKey, UIImage>()
    
    // MARK: - Init
    
    init() {}
    
    // MARK: - Methods
    
    @MainActor
    func topInnerShadow(
        width: CGFloat,
        height: CGFloat,
        radius: CGFloat,
        circle: Bool
    ) async -> UIImage {
        let key = TopInnerShadowKey(
            width: width,
            height: height,
            radius: radius,
            circle: circle
        )
        
        if let cached = topInnerShadowCache.get(key) {
            return cached
        }
        
        let image = GrantTopWhiteInnerShadow(
            width: width,
            height: height,
            radius: radius,
            circle: circle
        ).snapshot()
        
        topInnerShadowCache.set(key, value: image)
        return image
    }
    
    @MainActor
    func bottomInnerShadow(
        width: CGFloat,
        height: CGFloat,
        shadowColor: Color,
        radius: CGFloat,
        circle: Bool
    ) async -> UIImage {
        let key = BottomInnerShadowKey(
            width: width,
            height: height,
            shadowColor: shadowColor,
            radius: radius,
            circle: circle
        )
        
        if let cached = bottomInnerShadowCache.get(key) {
            return cached
        }
        
        let image = GrantBottomColorInnerShadow(
            width: width,
            height: height,
            shadowColor: shadowColor,
            radius: radius,
            circle: circle
        ).snapshot()
        
        bottomInnerShadowCache.set(key, value: image)
        return image
    }
    
    @MainActor
    func noiseImage(
        width: CGFloat,
        height: CGFloat
    ) async -> UIImage {
        let key = NoiseImageKey(width: width, height: height)
        
        if let cached = noiseImageCache.get(key) {
            return cached
        }
        
        guard
            let image = UIImage.makeNoiseImage(
                size: CGSize(width: width * 1.5, height: height * 1.5),
                intensity: 0.01
            )
        else {
            print("⚠️ [GrantsVolumeEffectService] Failed to generate noise image")
            return UIImage()
        }
        
        noiseImageCache.set(key, value: image)
        return image
    }
}

// MARK: - Thread-Safe Cache

private final class Cache<Key: Hashable, Value>: @unchecked Sendable {
    private var storage: [Key: Value] = [:]
    private let lock = NSLock()
    
    func get(_ key: Key) -> Value? {
        lock.lock()
        defer { lock.unlock() }
        return storage[key]
    }
    
    func set(_ key: Key, value: Value) {
        lock.lock()
        defer { lock.unlock() }
        storage[key] = value
    }
}

// MARK: - Dependencies

private enum GrantsVolumeEffectServiceKey: DependencyKey {
    static let liveValue: GrantsVolumeEffectService = LiveGrantsVolumeEffectService()
    static let testValue: GrantsVolumeEffectService = { fatalError() }()
}

extension DependencyValues {
    var grantsVolumeEffectService: GrantsVolumeEffectService {
        get { self[GrantsVolumeEffectServiceKey.self] }
        set { self[GrantsVolumeEffectServiceKey.self] = newValue }
    }
}

// MARK: - Helper Extensions

extension UIImage {
    /// Generate a noise texture image
    static func makeNoiseImage(size: CGSize, intensity: CGFloat = 0.01) -> UIImage? {
        let renderer = UIGraphicsImageRenderer(size: size)
        return renderer.image { context in
            let ctx = context.cgContext
            
            for _ in 0..<Int(size.width * size.height * intensity) {
                let x = CGFloat.random(in: 0..<size.width)
                let y = CGFloat.random(in: 0..<size.height)
                let brightness = CGFloat.random(in: 0.8...1.0)
                
                ctx.setFillColor(UIColor(white: brightness, alpha: 0.5).cgColor)
                ctx.fill(CGRect(x: x, y: y, width: 1, height: 1))
            }
        }
    }
}

extension UIImage {
    func asSUIImage() -> Image {
        Image(uiImage: self)
    }
}

