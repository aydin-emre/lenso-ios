//
//  UIButton+Extension.swift
//  Lenso
//
//  Created by Emre on 13.09.2025.
//

import UIKit

extension UIButton {
    
    @IBInspectable var localizedKey: String? {
        get { return nil }
        set { setTitle(newValue?.localized, for: .normal) }
    }
}
