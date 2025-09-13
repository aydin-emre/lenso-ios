//
//  String+Extension.swift
//  Lenso
//
//  Created by Emre on 13.09.2025.
//

import Foundation

extension String {
    
    /// Returns the localized version of the string
    var localized: String {
        NSLocalizedString(self, comment: "")
    }

    /// Localize with formatting arguments
    func localized(with arguments: CVarArg...) -> String {
        String(format: self.localized, arguments: arguments)
    }
}
