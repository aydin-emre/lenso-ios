//
//  BaseResponse.swift
//  DataProvider
//
//  Created by Emre on 13.09.2025.
//

public struct BaseResponse<T: Decodable>: Decodable {

    public let status: String
    public let message: String?
    public let data: T?

    var isSuccess: Bool {
        return status.lowercased() == "success"
    }

}
