//
//  PhotoEditingViewController.swift
//  Lenso
//
//  Created by Emre on 13.09.2025.
//

import UIKit
import DataProvider

class PhotoEditingViewController: UIViewController, UIImagePickerControllerDelegate {

    // MARK: - IBOutlets
    @IBOutlet weak var imageEditingView: ImageEditingView!
    @IBOutlet weak var collectionView: UICollectionView!

    // MARK: - Data
    var viewModel: PhotoEditingViewModel!
    private var selectedOverlayIndex: Int = 0
    private let cacheFilenamePrefix = "lenso_edited_"

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        viewModel.delegate = self
        fetchOverlays()
    }

    // MARK: - Setup
    private func setupUI() {
        setupNavigationButtons()
        setupCollectionView()
        setupImageEditingView()
    }

    private func setupNavigationButtons() {
        let appearance = UINavigationBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = .darkGray
        appearance.titleTextAttributes = [.foregroundColor: UIColor.white]
        appearance.largeTitleTextAttributes = [.foregroundColor: UIColor.white]
        navigationController?.navigationBar.standardAppearance = appearance
        navigationController?.navigationBar.scrollEdgeAppearance = appearance
        navigationController?.navigationBar.compactAppearance = appearance
        navigationController?.navigationBar.tintColor = .white

        let closeItem = UIBarButtonItem(image: UIImage(systemName: "xmark"), style: .plain,
                                        target: self, action: #selector(closeButtonTapped(_:)))
        let saveItem = UIBarButtonItem(image: UIImage(systemName: "checkmark"), style: .plain,
                                       target: self, action: #selector(saveButtonTapped(_:)))
        navigationItem.leftBarButtonItem = closeItem
        navigationItem.rightBarButtonItem = saveItem
    }

    private func setupCollectionView() {
        collectionView.delegate = self
        collectionView.dataSource = self
        collectionView.register(UINib(nibName: "OverlayCollectionViewCell", bundle: nil), forCellWithReuseIdentifier: "OverlayCell")

        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .horizontal
        layout.sectionHeadersPinToVisibleBounds = false
        layout.minimumInteritemSpacing = 0
        layout.minimumLineSpacing = 8
        layout.estimatedItemSize = .zero
        let height = max(1, collectionView.bounds.height - 8)
        layout.itemSize = CGSize(width: 80, height: height)
        collectionView.collectionViewLayout = layout
        collectionView.contentInset = UIEdgeInsets(top: 0, left: 8, bottom: 0, right: 8)
    }

    private func setupImageEditingView() {
        imageEditingView.setBaseImage(viewModel.selectedImage)
        imageEditingView.showHistogram = true
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        if let layout = collectionView.collectionViewLayout as? UICollectionViewFlowLayout {
            let height = max(1, collectionView.bounds.height - 8)
            if layout.itemSize.height != height {
                layout.itemSize = CGSize(width: 80, height: height)
                layout.invalidateLayout()
            }
        }
    }

    // MARK: - Image Handling
    private func applyOverlay(_ overlay: OverlayModel) {
        if let url = URL(string: overlay.overlayUrl) {
            Task { [weak self] in
                guard let self else { return }
                if let image = try? await DefaultOverlayImageClient.shared.fetchImage(at: url) {
                    await MainActor.run {
                        self.imageEditingView.setOverlayImage(image)
                    }
                } else {
                    await MainActor.run {
                        self.imageEditingView.clearOverlay()
                    }
                }
            }
        }
        if let index = viewModel.overlays.firstIndex(where: { $0.overlayId == overlay.overlayId }) {
            viewModel.selectOverlay(at: index)
        }
    }

    private func saveComposedImageToCache() {
        guard let finalImage = imageEditingView.composedImage() else {
            showAlert(title: "error.title".localized, message: "error.no_image".localized)
            return
        }

        let cachesDir = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first!
        let timestamp = Int(Date().timeIntervalSince1970)
        let jpegURL = cachesDir.appendingPathComponent("\(cacheFilenamePrefix)\(timestamp).jpg")

        if let data = finalImage.jpegData(compressionQuality: 0.9) {
            do {
                try data.write(to: jpegURL, options: .atomic)
                showAlert(title: "save.success.title".localized, message: "save.success.cache".localized(with: jpegURL.lastPathComponent))
                DispatchQueue.global(qos: .background).async { [weak self] in
                    self?.cleanupCachedImages()
                }
                return
            } catch {
                // Fall through to PNG attempt
            }
        }

        let pngURL = cachesDir.appendingPathComponent("\(cacheFilenamePrefix)\(timestamp).png")
        if let data = finalImage.pngData() {
            do {
                try data.write(to: pngURL, options: .atomic)
                showAlert(title: "save.success.title".localized, message: "save.success.cache".localized(with: pngURL.lastPathComponent))
                DispatchQueue.global(qos: .background).async { [weak self] in
                    self?.cleanupCachedImages()
                }
                return
            } catch {
                showAlert(title: "save.error.title".localized, message: error.localizedDescription)
                return
            }
        }

        showAlert(title: "save.error.title".localized, message: "save.error.encode".localized)
    }

    // MARK: - Cache Cleanup
    private func cleanupCachedImages(maxAgeDays: Int = 7, maxTotalBytes: Int64 = 100 * 1024 * 1024) {
        let fm = FileManager.default
        guard let cachesDir = fm.urls(for: .cachesDirectory, in: .userDomainMask).first else { return }
        let keys: Set<URLResourceKey> = [.contentModificationDateKey, .creationDateKey, .fileSizeKey]
        guard let urls = try? fm.contentsOfDirectory(at: cachesDir, includingPropertiesForKeys: Array(keys), options: [.skipsHiddenFiles]) else { return }

        func isEditedImage(_ url: URL) -> Bool {
            let name = url.lastPathComponent
            let ext = url.pathExtension.lowercased()
            return name.hasPrefix(cacheFilenamePrefix) && (ext == "jpg" || ext == "jpeg" || ext == "png")
        }

        var files = urls.filter { isEditedImage($0) }

        // Delete by age
        let expiration = Date().addingTimeInterval(-Double(maxAgeDays) * 24 * 60 * 60)
        for url in files {
            let values = try? url.resourceValues(forKeys: keys)
            let date = values?.contentModificationDate ?? values?.creationDate ?? Date.distantPast
            if date < expiration {
                try? fm.removeItem(at: url)
            }
        }

        // Recalculate remaining files and total size
        files = (try? fm.contentsOfDirectory(at: cachesDir, includingPropertiesForKeys: Array(keys), options: [.skipsHiddenFiles]))?.filter { isEditedImage($0) } ?? []
        var sizes: [URL: Int64] = [:]
        var total: Int64 = 0
        for url in files {
            let size = Int64((try? url.resourceValues(forKeys: [.fileSizeKey]).fileSize) ?? 0)
            sizes[url] = size
            total += size
        }

        if total > maxTotalBytes {
            // Delete oldest first until under limit
            let sorted = files.sorted { a, b in
                let va = try? a.resourceValues(forKeys: [.contentModificationDateKey, .creationDateKey])
                let vb = try? b.resourceValues(forKeys: [.contentModificationDateKey, .creationDateKey])
                let da = va?.contentModificationDate ?? va?.creationDate ?? Date.distantPast
                let db = vb?.contentModificationDate ?? vb?.creationDate ?? Date.distantPast
                return da < db
            }
            for url in sorted {
                if total <= maxTotalBytes { break }
                let size = sizes[url] ?? 0
                try? fm.removeItem(at: url)
                total -= size
            }
        }
    }

    private func showAlert(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
}

// MARK: - Actions
extension PhotoEditingViewController {

    @objc func closeButtonTapped(_ sender: Any) {
        dismiss(animated: true)
    }

    @objc func saveButtonTapped(_ sender: Any) {
        saveComposedImageToCache()
    }
}

// MARK: - Fetch Data
extension PhotoEditingViewController {

    private func fetchOverlays() {
        viewModel.fetchOverlays()
    }
}

// MARK: - UICollectionViewDataSource & UICollectionViewDelegate
extension PhotoEditingViewController: UICollectionViewDataSource, UICollectionViewDelegate {

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return (viewModel?.overlays.count ?? 0) + 1
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "OverlayCell", for: indexPath) as! OverlayCollectionViewCell
        if indexPath.item == 0 {
            let isSelected = indexPath.item == selectedOverlayIndex
            cell.configure(with: nil, isSelected: isSelected)
        } else if let overlay = viewModel?.overlay(at: indexPath.item) {
            let isSelected = indexPath.item == selectedOverlayIndex
            cell.configure(with: overlay, isSelected: isSelected)
        }
        return cell
    }

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        selectedOverlayIndex = indexPath.item
        viewModel.selectOverlay(at: indexPath.item)
        if indexPath.item == 0 {
            imageEditingView.clearOverlay()
        } else if let overlay = viewModel.overlay(at: indexPath.item) {
            applyOverlay(overlay)
        }
        collectionView.reloadData()
    }
}

// MARK: - PhotoEditingViewModelDelegate
extension PhotoEditingViewController: PhotoEditingViewModelDelegate {

    func viewModelDidUpdateImage(_ image: UIImage?) {
        imageEditingView.setBaseImage(image)
    }

    func viewModelDidUpdateOverlays() {
        self.collectionView.reloadData()
    }

    func viewModelDidFail(with message: String) {
        self.showAlert(title: "Error", message: message)
    }
}

// MARK: - StoryboardInstantiable
extension PhotoEditingViewController: StoryboardInstantiable {

    static var storyboard = Storyboard.PhotoEditing

}
