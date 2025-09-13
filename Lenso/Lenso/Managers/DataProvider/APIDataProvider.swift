//
//  APIDataProvider.swift
//  Lenso
//
//  Created by Emre on 13.09.2025.
//

import DataProvider
import Alamofire

public struct APIDataProvider: DataProviderProtocol {

    private let session: Session

    public init(eventMonitors: [EventMonitor] = []) {
        self.session = Session(eventMonitors: eventMonitors)
        self.session.sessionConfiguration.timeoutIntervalForRequest = 20
    }

    private func createRequest<T: RequestProtocol>(_ request: T) -> DataRequest {
        let adapter = APIRequestAdapter(request: request)
        return session.request(adapter.url,
                               method: adapter.method,
                               parameters: adapter.parameters,
                               encoding: adapter.encoding,
                               headers: adapter.headers)
    }

    public func request<T: DecodableResponseRequest>(for request: T, result: DataProviderResult<T.ResponseType>? = nil) {
        let request = createRequest(request)
        request.validate()
        request.responseDecodable(of: T.ResponseType.self) { response in
            switch response.result {
            case .success(let value):
                result?(.success(value))
            case .failure(let error):
                result?(.failure(error))
            }
        }
    }

}
