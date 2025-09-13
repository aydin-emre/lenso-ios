//
//  OverlayModel.swift
//  DataProvider
//
//  Created by Emre on 13.09.2025.
//

import Foundation

public struct OverlayModel: Decodable {
    public let overlayId: Int
    public let overlayName: String
    public let overlayPreviewIconUrl: String
    public let overlayUrl: String
    
    enum CodingKeys: String, CodingKey {
        case overlayId
        case overlayName
        case overlayPreviewIconUrl
        case overlayUrl
    }
}

