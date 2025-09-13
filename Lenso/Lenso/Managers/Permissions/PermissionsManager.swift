//
//  PermissionsManager.swift
//  Lenso
//
//  Created by Emre on 13.09.2025.
//

import Foundation
import UIKit
import AVFoundation
import Photos

enum AppPermission {
    case camera
    case photoLibraryReadWrite
    case photoLibraryAddOnly
}

enum PermissionStatus {
    case authorized
    case limited
    case denied
    case notDetermined
    case restricted
}

final class PermissionsManager {
    
    static let shared = PermissionsManager()

    // MARK: - Init
    private init() {}

    // MARK: - Public API
    func currentStatus(of permission: AppPermission) -> PermissionStatus {
        switch permission {
        case .camera:
            let status = AVCaptureDevice.authorizationStatus(for: .video)
            switch status {
            case .authorized:
                return .authorized
            case .notDetermined:
                return .notDetermined
            case .denied:
                return .denied
            case .restricted:
                return .restricted
            @unknown default:
                return .restricted
            }

        case .photoLibraryReadWrite:
            if #available(iOS 14, *) {
                let status = PHPhotoLibrary.authorizationStatus(for: .readWrite)
                switch status {
                case .authorized:
                    return .authorized
                case .limited:
                    return .limited
                case .denied:
                    return .denied
                case .notDetermined:
                    return .notDetermined
                case .restricted:
                    return .restricted
                @unknown default:
                    return .restricted
                }
            } else {
                let status = PHPhotoLibrary.authorizationStatus()
                switch status {
                case .authorized:
                    return .authorized
                case .denied:
                    return .denied
                case .notDetermined:
                    return .notDetermined
                case .restricted:
                    return .restricted
                @unknown default:
                    return .restricted
                }
            }

        case .photoLibraryAddOnly:
            if #available(iOS 14, *) {
                let status = PHPhotoLibrary.authorizationStatus(for: .addOnly)
                switch status {
                case .authorized:
                    return .authorized
                case .limited:
                    return .limited
                case .denied:
                    return .denied
                case .notDetermined:
                    return .notDetermined
                case .restricted:
                    return .restricted
                @unknown default:
                    return .restricted
                }
            } else {
                // Prior to iOS 14 there is no add-only; treat as general Photos permission
                let status = PHPhotoLibrary.authorizationStatus()
                switch status {
                case .authorized:
                    return .authorized
                case .denied:
                    return .denied
                case .notDetermined:
                    return .notDetermined
                case .restricted:
                    return .restricted
                @unknown default:
                    return .restricted
                }
            }
        }
    }

    func request(_ permission: AppPermission, completion: @escaping (PermissionStatus) -> Void) {
        switch permission {
        case .camera:
            AVCaptureDevice.requestAccess(for: .video) { granted in
                DispatchQueue.main.async {
                    completion(granted ? .authorized : .denied)
                }
            }

        case .photoLibraryReadWrite:
            if #available(iOS 14, *) {
                PHPhotoLibrary.requestAuthorization(for: .readWrite) { status in
                    DispatchQueue.main.async {
                        completion(self.mapPhotoStatus(status))
                    }
                }
            } else {
                PHPhotoLibrary.requestAuthorization { status in
                    DispatchQueue.main.async {
                        completion(self.mapLegacyPhotoStatus(status))
                    }
                }
            }

        case .photoLibraryAddOnly:
            if #available(iOS 14, *) {
                PHPhotoLibrary.requestAuthorization(for: .addOnly) { status in
                    DispatchQueue.main.async {
                        completion(self.mapPhotoStatus(status))
                    }
                }
            } else {
                // Fallback to legacy request
                PHPhotoLibrary.requestAuthorization { status in
                    DispatchQueue.main.async {
                        completion(self.mapLegacyPhotoStatus(status))
                    }
                }
            }
        }
    }

    func ensurePermission(_ permission: AppPermission, from presenter: UIViewController, completion: @escaping (Bool) -> Void) {
        let current = currentStatus(of: permission)
        switch current {
        case .authorized, .limited:
            completion(true)
        case .notDetermined:
            request(permission) { status in
                switch status {
                case .authorized, .limited:
                    completion(true)
                default:
                    completion(false)
                }
            }
        case .denied, .restricted:
            presentSettingsAlert(for: permission, from: presenter)
            completion(false)
        }
    }

    // MARK: - Helpers
    private func presentSettingsAlert(for permission: AppPermission, from presenter: UIViewController) {
        let messageKey: String
        switch permission {
        case .camera:
            messageKey = "permission.camera.message"
        case .photoLibraryReadWrite:
            messageKey = "permission.photos.readwrite.message"
        case .photoLibraryAddOnly:
            messageKey = "permission.photos.addonly.message"
        }

        let alert = UIAlertController(title: "permission.alert.title".localized, message: messageKey.localized, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "permission.alert.cancel".localized, style: .cancel))
        alert.addAction(UIAlertAction(title: "permission.alert.settings".localized, style: .default, handler: { _ in
            if let url = URL(string: UIApplication.openSettingsURLString) {
                UIApplication.shared.open(url, options: [:], completionHandler: nil)
            }
        }))

        presenter.present(alert, animated: true)
    }

    private func mapPhotoStatus(_ status: PHAuthorizationStatus) -> PermissionStatus {
        switch status {
        case .authorized:
            return .authorized
        case .limited:
            return .limited
        case .denied:
            return .denied
        case .notDetermined:
            return .notDetermined
        case .restricted:
            return .restricted
        @unknown default:
            return .restricted
        }
    }

    private func mapLegacyPhotoStatus(_ status: PHAuthorizationStatus) -> PermissionStatus {
        switch status {
        case .authorized:
            return .authorized
        case .denied:
            return .denied
        case .notDetermined:
            return .notDetermined
        case .restricted:
            return .restricted
        case .limited:
            return .limited
        @unknown default:
            return .restricted
        }
    }
}


