import UIKit
import Nuke
import SVGKit

/// Custom Nuke processor that converts SVG data to raster images using SVGKit
/// Works seamlessly with Nuke's caching system
struct SVGImageProcessor: ImageProcessing {
    
    let targetSize: CGSize
    
    init(targetSize: CGSize = CGSize(width: 88, height: 88)) {
        self.targetSize = targetSize
    }
    
    func process(_ image: PlatformImage) -> PlatformImage? {
        // For raster images that are already decoded
        print("🔧 SVGImageProcessor.process(image) called - resizing raster image")
        return image.resize(to: targetSize)
    }
    
    func process(_ container: ImageContainer, context: ImageProcessingContext) -> ImageContainer? {
        print("🔧 SVGImageProcessor.process(container) called")
        
        // Check if we have raw data (for SVG)
        if let svgData = container.data {
            print("   Found data: \(svgData.count) bytes")
            
            // Check if data looks like SVG
            if let dataString = String(data: svgData.prefix(100), encoding: .utf8),
               dataString.contains("<svg") {
                print("   Detected SVG content")
                
                // Try to render SVG to UIImage using SVGKit
                if let renderedImage = renderSVG(data: svgData, size: targetSize) {
                    return ImageContainer(image: renderedImage)
                }
            }
        }
        
        // For raster images, resize
        let resized = container.image.resize(to: targetSize)
        return ImageContainer(image: resized)
    }
    
    var identifier: String {
        "com.orb.svg-processor-\(Int(targetSize.width))x\(Int(targetSize.height))"
    }
    
    // MARK: - SVG Rendering
    
    private func renderSVG(data: Data, size: CGSize) -> UIImage? {
        print("🎨 SVGImageProcessor: Rendering SVG (\(data.count) bytes) to \(Int(size.width))x\(Int(size.height))")
        
        // Use SVGKit to parse and render the SVG
        guard let svgImage = SVGKImage(data: data) else {
            print("⚠️ SVGImageProcessor: Failed to parse SVG data")
            return nil
        }
        
        print("   ✅ SVG parsed successfully - original size: \(svgImage.size)")
        
        // Scale to target size
        svgImage.scaleToFit(inside: size)
        
        // Render to UIImage
        guard let renderedImage = svgImage.uiImage else {
            print("⚠️ SVGImageProcessor: Failed to render SVG to UIImage")
            return nil
        }
        
        print("   ✅ SVG rendered to image: \(renderedImage.size)")
        
        // Ensure it's exactly the target size
        let finalImage = renderedImage.resize(to: size)
        print("   ✅ Final resized image: \(finalImage.size)")
        
        return finalImage
    }
}

// MARK: - UIImage Extension

private extension UIImage {
    func resize(to targetSize: CGSize) -> UIImage {
        let renderer = UIGraphicsImageRenderer(size: targetSize)
        return renderer.image { _ in
            self.draw(in: CGRect(origin: .zero, size: targetSize))
        }
    }
}

// MARK: - Image Loading Extension

extension ImageRequest {
    
    /// Creates an image request optimized for SVG or raster images
    /// - Parameters:
    ///   - url: The image URL
    ///   - size: Target size for rendering
    /// - Returns: Configured ImageRequest
    static func forTokenIcon(url: URL, size: CGSize = CGSize(width: 88, height: 88)) -> ImageRequest {
        let urlString = url.absoluteString
        let isSVG = urlString.hasSuffix(".svg")
        
        print("🖼️ ImageRequest for: \(url.lastPathComponent) - isSVG: \(isSVG)")
        
        if isSVG {
            // For SVG, use custom processor
            return ImageRequest(
                url: url,
                processors: [SVGImageProcessor(targetSize: size)]
            )
        } else {
            // For raster images, use standard resize
            return ImageRequest(
                url: url,
                processors: [.resize(size: size)]
            )
        }
    }
}

