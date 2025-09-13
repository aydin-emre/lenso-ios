//
//  UILabel+Extension.swift
//  Lenso
//
//  Created by Emre on 13.09.2025.
//

import UIKit

extension UILabel {
    
    @IBInspectable var localizedKey: String? {
        get { return nil }
        set { text = newValue?.localized }
    }
}
