//
//  ImageEditingView.swift
//  Lenso
//
//  Created by Emre on 14.09.2025.
//

import UIKit
import CoreImage

final class ImageEditingView: UIView {

    // MARK: - IBOutlets
    @IBOutlet var contentView: UIView!
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var showHistogramContainerView: UIView!
    @IBOutlet weak var showHistogramSwitch: UISwitch!

    // MARK: - Private Views
    private var overlayImageView: UIImageView?
    private var overlayLoadTask: Task<Void, Never>?
    private var gesturesInstalled: Bool = false
    private let histogramImageView = UIImageView()
    private let ciContext = CIContext(options: nil)
    private var isHistogramEnabled: Bool = true

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupView()
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }

    override func awakeFromNib() {
        super.awakeFromNib()
        setupView()
    }

    override func prepareForInterfaceBuilder() {
        super.prepareForInterfaceBuilder()
        setupView()
    }

    private func setupView() {
        Bundle(for: type(of: self)).loadNibNamed(String(describing: type(of: self)), owner: self, options: nil)
        addSubview(contentView)
        contentView.frame = self.bounds
        contentView.autoresizingMask = [.flexibleHeight, .flexibleWidth]

        imageView.contentMode = .scaleAspectFit
        imageView.clipsToBounds = true
        imageView.backgroundColor = .black
        imageView.isUserInteractionEnabled = true

        // Histogram overlay setup
        histogramImageView.isUserInteractionEnabled = false
        histogramImageView.contentMode = .scaleAspectFit
        histogramImageView.alpha = 1.0
        histogramImageView.isHidden = true
        imageView.addSubview(histogramImageView)

        // Histogram UI controls
        showHistogramContainerView.isHidden = !showHistogram
        showHistogramSwitch.isOn = isHistogramEnabled
        showHistogramSwitch.addTarget(self, action: #selector(showHistogramChanged(_:)), for: .valueChanged)
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        layoutHistogram()
    }

    // MARK: - Helpers
    private func ensureOverlayView() {
        guard overlayImageView == nil else { return }

        let overlayView = UIImageView()
        overlayView.contentMode = .scaleAspectFit
        overlayView.isUserInteractionEnabled = true
        overlayView.translatesAutoresizingMaskIntoConstraints = true

        let container = imageView.bounds
        let size = CGSize(width: container.width * 0.6, height: container.height * 0.6)
        let origin = CGPoint(x: (container.width - size.width) / 2, y: (container.height - size.height) / 2)
        overlayView.frame = CGRect(origin: origin, size: size)

        imageView.addSubview(overlayView)
        overlayImageView = overlayView

        installGesturesIfNeeded()
    }

    private func installGesturesIfNeeded() {
        guard let overlayView = overlayImageView, gesturesInstalled == false else { return }

        let pan = UIPanGestureRecognizer(target: self, action: #selector(handlePan(_:)))
        let pinch = UIPinchGestureRecognizer(target: self, action: #selector(handlePinch(_:)))
        let rotate = UIRotationGestureRecognizer(target: self, action: #selector(handleRotate(_:)))

        pan.delegate = self
        pinch.delegate = self
        rotate.delegate = self

        overlayView.addGestureRecognizer(pan)
        overlayView.addGestureRecognizer(pinch)
        overlayView.addGestureRecognizer(rotate)

        gesturesInstalled = true
    }

    private func aspectFitRect(for imageSize: CGSize, in containerSize: CGSize) -> CGRect {
        guard imageSize.width > 0 && imageSize.height > 0 && containerSize.width > 0 && containerSize.height > 0 else {
            return CGRect(origin: .zero, size: containerSize)
        }
        let scale = min(containerSize.width / imageSize.width, containerSize.height / imageSize.height)
        let size = CGSize(width: imageSize.width * scale, height: imageSize.height * scale)
        let origin = CGPoint(x: (containerSize.width - size.width) / 2, y: (containerSize.height - size.height) / 2)
        return CGRect(origin: origin, size: size)
    }

    // MARK: - Histogram
    private func layoutHistogram() {
        guard showHistogram && isHistogramEnabled else { return }
        guard let base = imageView.image else {
            histogramImageView.frame = .zero
            return
        }
        let baseRect = aspectFitRect(for: base.size, in: imageView.bounds.size)
        let desiredWidth = min(140, baseRect.width * 0.35)
        let desiredHeight = max(60, desiredWidth * 0.6)
        let margin: CGFloat = 8
        let origin = CGPoint(x: baseRect.maxX - desiredWidth - margin, y: baseRect.maxY - desiredHeight - margin)
        histogramImageView.frame = CGRect(origin: origin, size: CGSize(width: desiredWidth, height: desiredHeight))
    }

    private func updateHistogram() {
        guard showHistogram && isHistogramEnabled else { return }
        let sourceImage = composedImage() ?? imageView.image
        guard let image = sourceImage else { histogramImageView.image = nil; return }
        layoutHistogram()
        histogramImageView.image = generateHistogramImage(for: image, size: histogramImageView.bounds.size)
    }

    @objc private func showHistogramChanged(_ sender: UISwitch) {
        isHistogramEnabled = sender.isOn
        updateHistogramVisibility()
        if isHistogramEnabled { updateHistogram() } else { histogramImageView.image = nil }
    }

    private func updateHistogramVisibility() {
        histogramImageView.isHidden = !(showHistogram && isHistogramEnabled)
    }

    private func generateHistogramImage(for image: UIImage, size: CGSize, bins: Int = 128) -> UIImage? {
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

        // Background
        let bgPath = UIBezierPath(roundedRect: CGRect(origin: .zero, size: size), cornerRadius: 6)
        UIColor.white.withAlphaComponent(0.6).setFill()
        bgPath.fill()

        // Curve fill
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

// MARK: - Public API
extension ImageEditingView {

    var showHistogram: Bool {
        get { return !showHistogramContainerView.isHidden }
        set {
            showHistogramContainerView.isHidden = !newValue
            if newValue { isHistogramEnabled = true }
            showHistogramSwitch?.isOn = isHistogramEnabled
            updateHistogramVisibility()
            if newValue { updateHistogram() } else { histogramImageView.image = nil }
        }
    }

    func setBaseImage(_ image: UIImage?) {
        imageView.image = image
        updateHistogram()
    }

    func clearOverlay() {
        overlayImageView?.removeFromSuperview()
        overlayImageView = nil
        gesturesInstalled = false
        updateHistogram()
    }

    func setOverlayImage(_ image: UIImage?) {
        if image == nil {
            clearOverlay()
            return
        }
        ensureOverlayView()
        overlayImageView?.image = image
    }

    func loadOverlay(from url: URL?) {
        overlayLoadTask?.cancel()
        guard let url else {
            clearOverlay()
            return
        }

        overlayLoadTask = Task { [weak self] in
            guard let self else { return }
            do {
                let (data, _) = try await URLSession.shared.data(from: url)
                if Task.isCancelled { return }
                if let image = UIImage(data: data) {
                    await MainActor.run { self.setOverlayImage(image) }
                } else {
                    await MainActor.run { self.clearOverlay() }
                }
            } catch {
                if Task.isCancelled { return }
                await MainActor.run { self.clearOverlay() }
            }
        }
    }

    func composedImage() -> UIImage? {
        let targetBounds = imageView.bounds
        guard targetBounds.size.width > 0, targetBounds.size.height > 0 else { return nil }

        let opaque = false
        UIGraphicsBeginImageContextWithOptions(targetBounds.size, opaque, 0.0)

        if let base = imageView.image {
            let baseRect = aspectFitRect(for: base.size, in: targetBounds.size)
            base.draw(in: baseRect)
        }

        if let overlayView = overlayImageView,
           let overlayImage = overlayView.image,
           let ctx = UIGraphicsGetCurrentContext() {
            ctx.saveGState()

            let center = overlayView.center
            ctx.translateBy(x: center.x, y: center.y)
            ctx.concatenate(overlayView.transform)
            let bounds = overlayView.bounds
            ctx.translateBy(x: -bounds.width / 2, y: -bounds.height / 2)

            let innerRect = aspectFitRect(for: overlayImage.size, in: bounds.size)
            overlayImage.draw(in: innerRect, blendMode: .screen, alpha: 1.0)

            ctx.restoreGState()
        }

        let final = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return final
    }
}

// MARK: - Gesture handlers
extension ImageEditingView {

    @objc private func handlePan(_ recognizer: UIPanGestureRecognizer) {
        guard let target = overlayImageView else { return }
        let translation = recognizer.translation(in: imageView)
        target.center = CGPoint(x: target.center.x + translation.x, y: target.center.y + translation.y)
        recognizer.setTranslation(.zero, in: imageView)
        if recognizer.state == .ended { updateHistogram() }
    }

    @objc private func handlePinch(_ recognizer: UIPinchGestureRecognizer) {
        guard let target = overlayImageView else { return }
        target.transform = target.transform.scaledBy(x: recognizer.scale, y: recognizer.scale)
        recognizer.scale = 1
        if recognizer.state == .ended { updateHistogram() }
    }

    @objc private func handleRotate(_ recognizer: UIRotationGestureRecognizer) {
        guard let target = overlayImageView else { return }
        target.transform = target.transform.rotated(by: recognizer.rotation)
        recognizer.rotation = 0
        if recognizer.state == .ended { updateHistogram() }
    }
}

// MARK: - UIGestureRecognizerDelegate
extension ImageEditingView: UIGestureRecognizerDelegate {

    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return true
    }
}
