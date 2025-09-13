//
//  BaseRequest.swift
//  DataProvider
//
//  Created by Emre on 13.09.2025.
//

import Foundation

public protocol BaseRequest: DecodableResponseRequest { }

public extension BaseRequest {

    var parameters: RequestParameters {
        return [:]
    }

    var headers: RequestHeaders {
        var headers: RequestHeaders = [:]
        headers["Content-Type"] = "application/x-www-form-urlencoded"

        if let token = AuthTokenManager.token {
            headers["Authorization"] = "Bearer \(token)"
        }

        return headers
    }

    var encoding: RequestEncoding {
        switch method {
        case .get:
            return .url
        case .post:
            return .urlEncodedForm
        default:
            return .json
        }
    }

    var url: String {
        return AppConfig.baseUrl + path
    }

    var requiresAuthentication: Bool { true }

}
