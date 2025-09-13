//
//  OverlayResponse.swift
//  DataProvider
//
//  Created by Emre on 13.09.2025.
//

import Foundation

public struct OverlayResponse: Decodable {
    public let overlays: [OverlayModel]
    
    enum CodingKeys: String, CodingKey {
        case overlays
    }
    
    public init(from decoder: Decoder) throws {
        // Since the JSON response is directly an array, we need to decode it as an array
        let container = try decoder.singleValueContainer()
        overlays = try container.decode([OverlayModel].self)
    }
}
