//
//  ImageProcessing.swift
//  Lenso
//
//  Created by Emre on 14.09.2025.
//

import UIKit
import CoreImage

protocol ImageProcessingProtocol {
    func aspectFitRect(for imageSize: CGSize, in containerSize: CGSize) -> CGRect
    func compose(base: UIImage?, overlay: UIImage?, targetSize: CGSize, overlayCenter: CGPoint?, overlayBounds: CGRect?, overlayTransform: CGAffineTransform?, blendMode: CGBlendMode) -> UIImage?
    func histogramImage(for image: UIImage, size: CGSize, bins: Int) -> UIImage?
}

struct DefaultImageProcessor: ImageProcessingProtocol {

    private let ciContext = CIContext(options: nil)

    func aspectFitRect(for imageSize: CGSize, in containerSize: CGSize) -> CGRect {
        guard imageSize.width > 0 && imageSize.height > 0 && containerSize.width > 0 && containerSize.height > 0 else {
            return CGRect(origin: .zero, size: containerSize)
        }
        let scale = min(containerSize.width / imageSize.width, containerSize.height / imageSize.height)
        let size = CGSize(width: imageSize.width * scale, height: imageSize.height * scale)
        let origin = CGPoint(x: (containerSize.width - size.width) / 2, y: (containerSize.height - size.height) / 2)
        return CGRect(origin: origin, size: size)
    }

    func compose(base: UIImage?, overlay: UIImage?, targetSize: CGSize, overlayCenter: CGPoint?, overlayBounds: CGRect?, overlayTransform: CGAffineTransform?, blendMode: CGBlendMode = .screen) -> UIImage? {
        guard targetSize.width > 0 && targetSize.height > 0 else { return nil }

        UIGraphicsBeginImageContextWithOptions(targetSize, false, 0.0)

        if let base = base {
            let baseRect = aspectFitRect(for: base.size, in: targetSize)
            base.draw(in: baseRect)
        }

        if let overlay = overlay, let center = overlayCenter, let bounds = overlayBounds, let transform = overlayTransform, let ctx = UIGraphicsGetCurrentContext() {
            ctx.saveGState()
            ctx.translateBy(x: center.x, y: center.y)
            ctx.concatenate(transform)
            ctx.translateBy(x: -bounds.width / 2, y: -bounds.height / 2)
            let innerRect = aspectFitRect(for: overlay.size, in: bounds.size)
            overlay.draw(in: innerRect, blendMode: blendMode, alpha: 1.0)
            ctx.restoreGState()
        }

        let result = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return result
    }

    func histogramImage(for image: UIImage, size: CGSize, bins: Int = 128) -> UIImage? {
        guard bins > 0, size.width > 0, size.height > 0, let ciImage = CIImage(image: image) else { return nil }
        let extent = ciImage.extent
        guard let filter = CIFilter(name: "CIAreaHistogram") else { return nil }
        filter.setValue(ciImage, forKey: kCIInputImageKey)
        filter.setValue(CIVector(x: extent.origin.x, y: extent.origin.y, z: extent.size.width, w: extent.size.height), forKey: "inputExtent")
        filter.setValue(bins, forKey: "inputCount")
        filter.setValue(1.0, forKey: "inputScale")
        guard let outputImage = filter.outputImage else { return nil }

        var raw = [UInt8](repeating: 0, count: bins * 4)
        ciContext.render(outputImage,
                         toBitmap: &raw,
                         rowBytes: bins * 4,
                         bounds: CGRect(x: 0, y: 0, width: bins, height: 1),
                         format: .RGBA8,
                         colorSpace: nil)

        var values = [CGFloat](repeating: 0, count: bins)
        for i in 0..<bins {
            let r = CGFloat(raw[i * 4 + 0])
            let g = CGFloat(raw[i * 4 + 1])
            let b = CGFloat(raw[i * 4 + 2])
            values[i] = 0.2126 * r + 0.7152 * g + 0.0722 * b
        }
        let maxValue = max(values.max() ?? 1, 1)

        UIGraphicsBeginImageContextWithOptions(size, false, 0)
        let ctx = UIGraphicsGetCurrentContext()

        let bgPath = UIBezierPath(roundedRect: CGRect(origin: .zero, size: size), cornerRadius: 6)
        UIColor.white.withAlphaComponent(0.6).setFill()
        bgPath.fill()

        let path = UIBezierPath()
        path.move(to: CGPoint(x: 0, y: size.height))
        for i in 0..<bins {
            let x = CGFloat(i) / CGFloat(bins - 1) * size.width
            let normalized = values[i] / maxValue
            let y = size.height - normalized * size.height
            path.addLine(to: CGPoint(x: x, y: y))
        }
        path.addLine(to: CGPoint(x: size.width, y: size.height))
        path.close()
        UIColor.black.withAlphaComponent(0.85).setFill()
        path.fill()

        ctx?.setStrokeColor(UIColor.black.withAlphaComponent(0.2).cgColor)
        ctx?.setLineWidth(1)
        ctx?.stroke(CGRect(origin: .zero, size: size))

        let result = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return result
    }
}


