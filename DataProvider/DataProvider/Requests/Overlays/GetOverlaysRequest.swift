//
//  GetOverlaysRequest.swift
//  DataProvider
//
//  Created by Emre on 13.09.2025.
//

import Foundation

public struct GetOverlaysRequest: BaseRequest {

    public typealias ResponseType = OverlayResponse

    public var path: String = "overlay.json"
    public var method: RequestMethod = .get
    
    public init() {}
}
