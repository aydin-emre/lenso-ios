//
//  PhotoEditingViewController.swift
//  Lenso
//
//  Created by Emre on 13.09.2025.
//

import UIKit
import DataProvider

class PhotoEditingViewController: UIViewController, UIImagePickerControllerDelegate {

    @IBOutlet weak var mainImageView: UIImageView!
    @IBOutlet weak var collectionView: UICollectionView!

    // MARK: - Data
    var viewModel: PhotoEditingViewModel!
    private var overlayImageView: UIImageView?
    private var selectedOverlayIndex: Int = 0

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupCollectionView()
        viewModel.delegate = self
        self.mainImageView.image = viewModel.selectedImage
        fetchOverlays()
    }

    // MARK: - Setup
    private func setupUI() {
        mainImageView.contentMode = .scaleAspectFit
        mainImageView.clipsToBounds = true
        mainImageView.backgroundColor = .black
        mainImageView.isUserInteractionEnabled = true

        setupNavigationButtons()
        setupCollectionView()
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
    private func applyOverlay(_ overlay: OverlayModel, to image: UIImage) {
        overlayImageView?.removeFromSuperview()

        let overlayView = UIImageView()
        overlayView.contentMode = .scaleAspectFit
        overlayView.translatesAutoresizingMaskIntoConstraints = false

        mainImageView.addSubview(overlayView)
        NSLayoutConstraint.activate([
            overlayView.centerXAnchor.constraint(equalTo: mainImageView.centerXAnchor),
            overlayView.centerYAnchor.constraint(equalTo: mainImageView.centerYAnchor),
            overlayView.widthAnchor.constraint(equalTo: mainImageView.widthAnchor, multiplier: 0.6),
            overlayView.heightAnchor.constraint(equalTo: mainImageView.heightAnchor, multiplier: 0.6)
        ])

        if let url = URL(string: overlay.overlayUrl) {
            URLSession.shared.dataTask(with: url) { data, response, error in
                guard let data = data, let overlayImage = UIImage(data: data) else { return }

                DispatchQueue.main.async {
                    overlayView.image = overlayImage
                }
            }.resume()
        }

        overlayImageView = overlayView
        if let index = viewModel.overlays.firstIndex(where: { $0.overlayId == overlay.overlayId }) {
            viewModel.selectOverlay(at: index)
        }
    }

    private func saveImageWithOverlay(_ image: UIImage) {
        UIGraphicsBeginImageContextWithOptions(mainImageView.bounds.size, false, 0.0)

        image.draw(in: mainImageView.bounds)

        if let overlayImage = overlayImageView?.image {
            let overlayFrame = overlayImageView?.frame ?? CGRect.zero
            overlayImage.draw(in: overlayFrame)
        }

        let combinedImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()

        if let finalImage = combinedImage {
            UIImageWriteToSavedPhotosAlbum(finalImage, self, #selector(image(_:didFinishSavingWithError:contextInfo:)), nil)
        }
    }

    @objc private func image(_ image: UIImage, didFinishSavingWithError error: Error?, contextInfo: UnsafeRawPointer) {
        if let error = error {
            showAlert(title: "Save Error", message: error.localizedDescription)
        } else {
            showAlert(title: "Success", message: "Image saved to Photos!")
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
        guard let image = viewModel.selectedImage else {
            showAlert(title: "error.title".localized, message: "error.no_image".localized)
            return
        }
        saveImageWithOverlay(image)
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
            overlayImageView?.removeFromSuperview()
            overlayImageView = nil
        } else if let base = viewModel.selectedImage, let overlay = viewModel.overlay(at: indexPath.item) {
            applyOverlay(overlay, to: base)
        }
        collectionView.reloadData()
    }
}

// MARK: - PhotoEditingViewModelDelegate
extension PhotoEditingViewController: PhotoEditingViewModelDelegate {
    func viewModelDidUpdateImage(_ image: UIImage?) {
        self.mainImageView.image = image
    }

    func viewModelDidUpdateOverlays() {
        self.collectionView.reloadData()
    }

    func viewModelDidFail(with message: String) {
        self.showAlert(title: "Error", message: message)
    }
}

extension PhotoEditingViewController: StoryboardInstantiable {

    static var storyboard = Storyboard.PhotoEditing

}
