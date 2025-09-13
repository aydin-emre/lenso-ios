//
//  APILogger.swift
//  Lenso
//
//  Created by Emre on 13.09.2025.
//

import Foundation
import Alamofire

final class APILogger: EventMonitor {

    static let shared = APILogger()

    let queue = DispatchQueue(label: "com.ea.lenso.networklogger")

    func request(_ request: Request, didCreateURLRequest urlRequest: URLRequest) {
        print("---> Request Created <---")
        print(request.description)
    }

    func requestDidFinish(_ request: Request) {
        print("---> Request Finished <---")
        print(request.description)
    }
    func request<Value>(_ request: DataRequest, didParseResponse response: DataResponse<Value, AFError>) {
        print("---> Request JSONResponse <---")
        if let data = response.data, let json = String(data: data, encoding: .utf8) {
            print(json)
        }
    }
}
