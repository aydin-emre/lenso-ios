//
//  DataProviderProtocol.swift
//  DataProvider
//
//  Created by Emre on 13.09.2025.
//

public typealias DataProviderResult<T: Decodable> = ((Result<T, Error>) -> Void)

public protocol DataProviderProtocol {

    func request<T: DecodableResponseRequest>(for request: T,
                                              result: DataProviderResult<T.ResponseType>?)
}
