//
//  DataProvider.swift
//  Lenso
//
//  Created by Emre on 13.09.2025.
//

#if DEBUG
let apiDataProvider = APIDataProvider(eventMonitors: [APILogger.shared])
#else
let apiDataProvider = APIDataProvider(eventMonitors: [])
#endif
