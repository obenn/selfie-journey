import UIKit

enum PortraitImageProcessor {
    /// Bakes orientation and the centered 3:4 viewfinder crop into every frame.
    static func jpegData(from image: UIImage) throws -> Data {
        guard image.size.width > 0, image.size.height > 0 else { throw ImageError.invalidImage }
        let canvas = CGSize(width: 1200, height: 1600)
        let scale = max(canvas.width / image.size.width, canvas.height / image.size.height)
        let size = CGSize(width: image.size.width * scale, height: image.size.height * scale)
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1
        format.opaque = true
        let normalized = UIGraphicsImageRenderer(size: canvas, format: format).image { context in
            UIColor.black.setFill()
            context.fill(CGRect(origin: .zero, size: canvas))
            image.draw(in: CGRect(x: (canvas.width - size.width) / 2,
                                  y: (canvas.height - size.height) / 2,
                                  width: size.width, height: size.height))
        }
        guard let data = normalized.jpegData(compressionQuality: 0.9) else { throw ImageError.invalidImage }
        return data
    }

    enum ImageError: LocalizedError {
        case invalidImage
        var errorDescription: String? { "This photo couldn't be read. Please try another portrait." }
    }
}
