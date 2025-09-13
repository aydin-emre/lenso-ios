//
//  HomeViewController.swift
//  Lenso
//
//  Created by Emre on 13.09.2025.
//

import UIKit
import SwiftUI
import Photos
import DataProvider

class HomeViewController: UIViewController {

    // MARK: - IBOutlets
    @IBOutlet weak var cameraPickerView: UIView!
    @IBOutlet weak var libraryPickerView: UIView!
    @IBOutlet weak var requestPermissionView: UIView!
    @IBOutlet weak var collectionView: UICollectionView!
    
//    @IBOutlet weak var mainImageView: UIImageView!
//    @IBOutlet weak var overlayCollectionView: UICollectionView!
    
    // MARK: - Photos Grid
    private var photoAssets: [PHAsset] = []
    private let imageManager = PHCachingImageManager()
    private var selectedImage: UIImage?
    
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        configureContent()
        setupCollectionView()
//        setupUI()
//        setupCollectionView()
//        fetchOverlays()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        updatePermissionUI()
    }
    
    private func updatePermissionUI() {
        let status = PermissionsManager.shared.currentStatus(of: .photoLibraryReadWrite)
        switch status {
        case .authorized, .limited:
            requestPermissionView.isHidden = true
            if photoAssets.isEmpty { fetchLibraryPhotos() }
        case .denied, .restricted, .notDetermined:
            showPermissionPrompt()
        }
    }

    // MARK: - Content
    private func configureContent() {
        let cameraTile = PhotoPickerView(title: "home.camera.title".localized, systemImageName: "camera") { [weak self] in
            guard let self = self else { return }
            PermissionsManager.shared.ensurePermission(.camera, from: self) { [weak self] granted in
                guard let self = self else { return }
                if granted { self.presentCamera() }
            }
        }
        addSwiftUIView(into: cameraPickerView, cameraTile)

        let libraryTile = PhotoPickerView(title: "home.album.title".localized, systemImageName: "photo.on.rectangle") { [weak self] in
            guard let self = self else { return }
            PermissionsManager.shared.ensurePermission(.photoLibraryReadWrite, from: self) { [weak self] granted in
                guard let self = self else { return }
                if granted { self.presentPhotoLibrary() }
            }
        }
        addSwiftUIView(into: libraryPickerView, libraryTile)

        requestPermissionView.isHidden = true
    }

    // MARK: - Permission Prompt
    private func showPermissionPrompt() {
        requestPermissionView.isHidden = false
        requestPermissionView.subviews.forEach { $0.removeFromSuperview() }
        let view = PermissionPromptView(
            message: "permission.prompt.message".localized,
            buttonTitle: "permission.prompt.button".localized,
            onContinue: { [weak self] in
                guard let self = self else { return }
                PermissionsManager.shared.request(.photoLibraryReadWrite) { [weak self] status in
                    guard let self = self else { return }
                    switch status {
                    case .authorized, .limited:
                        self.requestPermissionView.isHidden = true
                        self.updatePermissionUI()
                    default:
                        break
                    }
                }
            }
        )
        addSwiftUIView(into: requestPermissionView, view)
    }
}

// MARK: - Pickers
extension HomeViewController {

    private func presentCamera() {
        guard UIImagePickerController.isSourceTypeAvailable(.camera) else { return }
        let picker = UIImagePickerController()
        picker.sourceType = .camera
        picker.allowsEditing = false
        picker.delegate = self
        present(picker, animated: true)
    }

    private func presentPhotoLibrary() {
        guard UIImagePickerController.isSourceTypeAvailable(.photoLibrary) else { return }
        let picker = UIImagePickerController()
        picker.sourceType = .photoLibrary
        picker.allowsEditing = false
        picker.delegate = self
        present(picker, animated: true)
    }
}

// MARK: - Photos Grid Setup
extension HomeViewController {

    private func fetchLibraryPhotos() {
        let fetchOptions = PHFetchOptions()
        fetchOptions.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
        fetchOptions.fetchLimit = 100

        let assets = PHAsset.fetchAssets(with: .image, options: fetchOptions)
        var results: [PHAsset] = []
        assets.enumerateObjects { asset, _, _ in
            results.append(asset)
        }
        photoAssets = results
        collectionView.reloadData()
    }

    private func setupCollectionView() {
        collectionView.backgroundColor = .clear
        collectionView.dataSource = self
        collectionView.delegate = self
        collectionView.register(PhotoGridCell.self, forCellWithReuseIdentifier: PhotoGridCell.reuseIdentifier)

        if let layout = collectionView.collectionViewLayout as? UICollectionViewFlowLayout {
            let spacing: CGFloat = 3
            layout.minimumInteritemSpacing = spacing
            layout.minimumLineSpacing = spacing
            let columns: CGFloat = 3
            let width = collectionView.bounds.width
            let totalSpacing = spacing * (columns - 1)
            let itemWidth = floor((width - totalSpacing) / columns)
            layout.itemSize = CGSize(width: itemWidth, height: itemWidth)
            collectionView.contentInset = .zero
        }
    }
}

// MARK: - UICollectionViewDataSource
extension HomeViewController: UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return photoAssets.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: PhotoGridCell.reuseIdentifier, for: indexPath) as! PhotoGridCell
        let asset = photoAssets[indexPath.item]
        cell.configure(with: asset, imageManager: imageManager)
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let spacing: CGFloat = 3
        let columns: CGFloat = 3
        let totalSpacing = spacing * (columns - 1)
        let width = collectionView.bounds.width
        let itemWidth = floor((width - totalSpacing) / columns)
        return CGSize(width: itemWidth, height: itemWidth)
    }
}

// MARK: - UIImagePickerControllerDelegate
extension HomeViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {

    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        if let image = info[.originalImage] as? UIImage {
            self.selectedImage = image
        }
        picker.dismiss(animated: true)
    }
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true)
    }
}
