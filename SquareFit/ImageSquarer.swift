import UIKit

/// Pads an image to a 1:1 aspect ratio by centering it on a white canvas.
enum ImageSquarer {
    /// Returns a square image whose side equals the longer side of `image`.
    /// The original pixels are untouched; the extra area is filled with white.
    static func square(_ image: UIImage, background: UIColor = .white) -> UIImage {
        // Work in pixel space so we never downscale the original photo.
        let scale = image.scale
        let width = image.size.width * scale
        let height = image.size.height * scale
        let side = max(width, height)

        // Already square: nothing to do.
        if width == height { return image }

        let format = UIGraphicsImageRendererFormat()
        format.scale = 1
        format.opaque = true // White background, no alpha channel needed.

        let renderer = UIGraphicsImageRenderer(
            size: CGSize(width: side, height: side),
            format: format
        )

        let origin = CGPoint(x: (side - width) / 2, y: (side - height) / 2)

        return renderer.image { context in
            background.setFill()
            context.fill(CGRect(x: 0, y: 0, width: side, height: side))
            // UIImage.draw(in:) honours the EXIF orientation, so the result is upright.
            image.draw(in: CGRect(origin: origin, size: CGSize(width: width, height: height)))
        }
    }
}
