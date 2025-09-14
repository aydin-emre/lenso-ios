//
//  OverlayImageClient.swift
//  Lenso
//
//  Created by Emre on 14.09.2025.
//

import UIKit

enum OverlayImageClientError: Error {
    case invalidData
}

protocol OverlayImageClientProtocol {
    func fetchImage(at url: URL) async throws -> UIImage
}

final class DefaultOverlayImageClient: OverlayImageClientProtocol {

    static let shared = DefaultOverlayImageClient()
    private init() {}

    func fetchImage(at url: URL) async throws -> UIImage {
        // Reuse disk cache for offline support
        if let image = try? await DiskImageCache.shared.image(for: url) {
            return image
        }
        // Fallback plain download
        let (data, _) = try await URLSession.shared.data(from: url)
        guard let image = UIImage(data: data) else { throw OverlayImageClientError.invalidData }
        return image
    }
}
