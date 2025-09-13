//
//  RequestProtocol.swift
//  DataProvider
//
//  Created by Emre on 13.09.2025.
//

public protocol RequestProtocol {
    var path: String { get }
    var method: RequestMethod { get }
    var parameters: RequestParameters { get }
    var headers: RequestHeaders { get }
    var encoding: RequestEncoding { get }
    var url: String { get }
    var requiresAuthentication: Bool { get }
}
