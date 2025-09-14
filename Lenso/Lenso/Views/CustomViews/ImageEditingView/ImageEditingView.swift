//
//  ImageEditingView.swift
//  Lenso
//
//  Created by Emre on 14.09.2025.
//

import UIKit

final class ImageEditingView: UIView {
    
    // MARK: - IBOutlets
    @IBOutlet var contentView: UIView!
    @IBOutlet weak var imageView: UIImageView!
    
    // MARK: - Private Views
    private var overlayImageView: UIImageView?
    private var overlayLoadTask: Task<Void, Never>?
    private var gesturesInstalled: Bool = false
    
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
}

// MARK: - Public API
extension ImageEditingView {
    
    func setBaseImage(_ image: UIImage?) {
        imageView.image = image
    }
    
    func clearOverlay() {
        overlayImageView?.removeFromSuperview()
        overlayImageView = nil
        gesturesInstalled = false
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
    }
    
    @objc private func handlePinch(_ recognizer: UIPinchGestureRecognizer) {
        guard let target = overlayImageView else { return }
        target.transform = target.transform.scaledBy(x: recognizer.scale, y: recognizer.scale)
        recognizer.scale = 1
    }
    
    @objc private func handleRotate(_ recognizer: UIRotationGestureRecognizer) {
        guard let target = overlayImageView else { return }
        target.transform = target.transform.rotated(by: recognizer.rotation)
        recognizer.rotation = 0
    }
}

// MARK: - UIGestureRecognizerDelegate
extension ImageEditingView: UIGestureRecognizerDelegate {
    
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return true
    }
}
