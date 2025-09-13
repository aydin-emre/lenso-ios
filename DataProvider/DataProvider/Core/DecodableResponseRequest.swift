//
//  DecodableResponseRequest.swift
//  DataProvider
//
//  Created by Emre on 13.09.2025.
//

public protocol DecodableResponseRequest: RequestProtocol {
    associatedtype ResponseType: Decodable
}
