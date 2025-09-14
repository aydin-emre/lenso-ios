//
//  PhotoEditingViewModel.swift
//  Lenso
//
//  Created by Emre on 13.09.2025.
//

import UIKit
import DataProvider

protocol PhotoEditingViewModelDelegate: AnyObject {
    func viewModelDidUpdateImage(_ image: UIImage?)
    func viewModelDidUpdateOverlays()
    func viewModelDidFail(with message: String)
}

final class PhotoEditingViewModel {

    weak var delegate: PhotoEditingViewModelDelegate?

    private(set) var selectedImage: UIImage? {
        didSet { delegate?.viewModelDidUpdateImage(selectedImage) }
    }

    private(set) var overlays: [OverlayModel] = [] {
        didSet { delegate?.viewModelDidUpdateOverlays() }
    }

    private(set) var selectedOverlay: OverlayModel?

    init(initialImage: UIImage? = nil) {
        self.selectedImage = initialImage
    }

    func setImage(_ image: UIImage?) {
        selectedImage = image
    }

    func fetchOverlays() {
        // First deliver cached overlays if any
        let cached = OverlayStore.shared.load()
        if !cached.isEmpty {
            self.overlays = cached
        }

        let request = GetOverlaysRequest()
        apiDataProvider.request(for: request) { [weak self] result in
            DispatchQueue.main.async { [weak self] in
                guard let self else { return }
                switch result {
                case .success(let response):
                    self.overlays = response.overlays
                    OverlayStore.shared.save(response.overlays)
                case .failure(let error):
                    if cached.isEmpty {
                        self.delegate?.viewModelDidFail(with: "Failed to load overlays. Please try again. (\(error.localizedDescription))")
                    }
                }
            }
        }
    }

    func overlay(at index: Int) -> OverlayModel? {
        if index == 0 { return nil }
        let adjusted = index - 1
        guard overlays.indices.contains(adjusted) else { return nil }
        return overlays[adjusted]
    }

    func selectOverlay(at index: Int) {
        if index == 0 {
            selectedOverlay = nil
        } else {
            selectedOverlay = overlay(at: index)
        }
    }
}
