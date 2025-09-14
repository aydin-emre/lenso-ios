//
//  OverlayStore.swift
//  Lenso
//
//  Created by Emre on 14.09.2025.
//

import Foundation
import DataProvider

final class OverlayStore {

	static let shared = OverlayStore()

	private let fileManager = FileManager.default
	private let storeURL: URL
	private init() {
		let caches = fileManager.urls(for: .cachesDirectory, in: .userDomainMask).first!
		storeURL = caches.appendingPathComponent("overlays.json")
	}

	func load() -> [OverlayModel] {
		guard let data = try? Data(contentsOf: storeURL) else { return [] }
		let decoder = JSONDecoder()
		return (try? decoder.decode([OverlayModel].self, from: data)) ?? []
	}

	func save(_ overlays: [OverlayModel]) {
		let encoder = JSONEncoder()
		encoder.outputFormatting = .withoutEscapingSlashes
		if let data = try? encoder.encode(overlays) {
			do {
				try data.write(to: storeURL, options: .atomic)
			} catch {
				try? data.write(to: storeURL)
			}
		}
	}
}
