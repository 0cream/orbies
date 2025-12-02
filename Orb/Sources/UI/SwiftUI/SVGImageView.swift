import SwiftUI
import SVGKit

/// A view that loads and displays SVG images
struct SVGImageView: View {
    let url: URL
    let size: CGSize
    
    @State private var image: UIImage?
    @State private var isLoading = true
    @State private var loadError: Error?
    
    var body: some View {
        Group {
            if let image = image {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } else if loadError != nil {
                Color.clear
            } else {
                Color.clear
            }
        }
        .task {
            await loadSVG()
        }
    }
    
    private func loadSVG() async {
        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            
            guard let svgImage = SVGKImage(data: data) else {
                print("❌ Failed to parse SVG from: \(url.absoluteString)")
                loadError = NSError(domain: "SVG", code: -1)
                isLoading = false
                return
            }
            
            // Scale to target size
            svgImage.scaleToFit(inside: size)
            
            guard let renderedImage = svgImage.uiImage else {
                print("❌ Failed to render SVG to UIImage")
                loadError = NSError(domain: "SVG", code: -2)
                isLoading = false
                return
            }
            
            // Resize to exact size
            let renderer = UIGraphicsImageRenderer(size: size)
            let finalImage = renderer.image { _ in
                renderedImage.draw(in: CGRect(origin: .zero, size: size))
            }
            
            await MainActor.run {
                self.image = finalImage
                self.isLoading = false
            }
            
            print("✅ SVG loaded and rendered: \(url.lastPathComponent)")
            
        } catch {
            print("❌ Failed to download SVG: \(error.localizedDescription)")
            loadError = error
            isLoading = false
        }
    }
}

