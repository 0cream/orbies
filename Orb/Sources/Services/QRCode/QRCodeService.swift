import Dependencies
import Foundation
import UIKit
import QRCode

// MARK: - QRCode Service Protocol

/// Service for generating QR codes with custom styling
protocol QRCodeService: Sendable {
    /// Generate a QR code image with embedded logo
    /// - Parameters:
    ///   - content: The content to encode (e.g., wallet address)
    ///   - logo: Logo image to embed in center (optional)
    /// - Returns: Generated QR code as CGImage
    func generateCode(for content: String, logo: UIImage?) -> CGImage?
}

// MARK: - Live Implementation

struct LiveQRCodeService: QRCodeService {
    
    func generateCode(for content: String, logo: UIImage? = nil) -> CGImage? {
        do {
            let doc = try QRCode.Document(utf8String: content, errorCorrection: .medium)
            
            // Rounded design
            doc.design.shape.eye = QRCode.EyeShape.Circle()
            doc.design.shape.onPixels = QRCode.PixelShape.Horizontal(
                insetFraction: 0.2,
                cornerRadiusFraction: 1
            )
            
            // Add logo in center if provided
            if let logo = logo, let cgImage = logo.cgImage {
                doc.logoTemplate = QRCode.LogoTemplate.CircleCenter(
                    image: cgImage,
                    inset: 40
                )
            }
            
            return try doc.cgImage(CGSize(width: 1024, height: 1024))
        } catch {
            print("❌ Failed to generate QR code: \(error)")
            return nil
        }
    }
}

// MARK: - Dependency Registration

extension DependencyValues {
    var qrCodeService: QRCodeService {
        get { self[QRCodeServiceKey.self] }
        set { self[QRCodeServiceKey.self] = newValue }
    }
}

private enum QRCodeServiceKey: DependencyKey {
    static let liveValue: QRCodeService = LiveQRCodeService()
    static let testValue: QRCodeService = LiveQRCodeService()
}

