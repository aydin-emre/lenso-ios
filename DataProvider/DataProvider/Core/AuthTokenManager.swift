//
//  AuthTokenManager.swift
//  DataProvider
//
//  Created by Emre on 13.09.2025.
//

import Foundation

public final class AuthTokenManager {
    public static var token: String? {
        get {
            return UserDefaults.standard.string(forKey: "auth_token")
        }
        set {
            if let token = newValue {
                UserDefaults.standard.set(token, forKey: "auth_token")
            } else {
                UserDefaults.standard.removeObject(forKey: "auth_token")
            }
        }
    }
    
    public static func clearToken() {
        token = nil
    }
}
