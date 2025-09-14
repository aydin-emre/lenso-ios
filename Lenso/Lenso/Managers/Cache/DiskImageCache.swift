//
//  DiskImageCache.swift
//  Lenso
//
//  Created by Emre on 14.09.2025.
//

import Foundation
import UIKit
import CryptoKit

final class DiskImageCache {

	static let shared = DiskImageCache()

	private let ioQueue = DispatchQueue(label: "com.lenso.diskImageCache")
	private let fileManager = FileManager.default
	private let cacheDirectory: URL

	private init() {
		let caches = fileManager.urls(for: .cachesDirectory, in: .userDomainMask).first!
		cacheDirectory = caches.appendingPathComponent("ImageCache", isDirectory: true)
		try? fileManager.createDirectory(at: cacheDirectory, withIntermediateDirectories: true)
	}

	func image(for url: URL) async throws -> UIImage {
		let path = fileURL(for: url)
		if fileManager.fileExists(atPath: path.path),
		   let data = try? Data(contentsOf: path),
		   let image = UIImage(data: data) {
			return image
		}

		let (data, _) = try await URLSession.shared.data(from: url)
		if let image = UIImage(data: data) {
			let fileURL = path
			let bytes = data
			ioQueue.async {
				try? bytes.write(to: fileURL, options: .atomic)
			}
			return image
		}
		throw NSError(domain: "DiskImageCache", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid image data"])
	}

	private func persist(data: Data, to url: URL) throws {
		try data.write(to: url, options: .atomic)
	}

	private func fileURL(for url: URL) -> URL {
		let key = sha256(url.absoluteString)
		let ext = url.pathExtension.isEmpty ? "dat" : url.pathExtension
		return cacheDirectory.appendingPathComponent("\(key).\(ext)")
	}

	private func sha256(_ string: String) -> String {
		let data = Data(string.utf8)
		let digest = SHA256.hash(data: data)
		return digest.map { String(format: "%02x", $0) }.joined()
	}
}
