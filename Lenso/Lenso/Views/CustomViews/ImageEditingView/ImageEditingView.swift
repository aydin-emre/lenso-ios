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
    private var gesturesInstalled: Bool = false
    private let histogramImageView = UIImageView()
    private let imageProcessor: ImageProcessingProtocol = DefaultImageProcessor()
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

        histogramImageView.isUserInteractionEnabled = false
        histogramImageView.contentMode = .scaleAspectFit
        histogramImageView.alpha = 1.0
        histogramImageView.isHidden = true
        imageView.addSubview(histogramImageView)

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
        imageProcessor.aspectFitRect(for: imageSize, in: containerSize)
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
        histogramImageView.image = imageProcessor.histogramImage(for: image, size: histogramImageView.bounds.size, bins: 128)
    }

    @objc private func showHistogramChanged(_ sender: UISwitch) {
        isHistogramEnabled = sender.isOn
        updateHistogramVisibility()
        if isHistogramEnabled { updateHistogram() } else { histogramImageView.image = nil }
    }

    private func updateHistogramVisibility() {
        histogramImageView.isHidden = !(showHistogram && isHistogramEnabled)
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

    func composedImage() -> UIImage? {
        let targetBounds = imageView.bounds
        guard targetBounds.size.width > 0, targetBounds.size.height > 0 else { return nil }

        let center = overlayImageView?.center
        let bounds = overlayImageView?.bounds
        let transform = overlayImageView?.transform

        return imageProcessor.compose(
            base: imageView.image,
            overlay: overlayImageView?.image,
            targetSize: targetBounds.size,
            overlayCenter: center,
            overlayBounds: bounds,
            overlayTransform: transform,
            blendMode: .screen
        )
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
