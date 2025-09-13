//
//  UIApplication+Extension.swift
//  Lenso
//
//  Created by Emre on 13.09.2025.
//

import UIKit

extension UIApplication {

    class func topViewController(base: UIViewController? = rootViewController()) -> UIViewController? {
        if let nav = base as? UINavigationController {
            return topViewController(base: nav.visibleViewController)
        } else if let tab = base as? UITabBarController, let selected = tab.selectedViewController {
            return topViewController(base: selected)
        } else if let presented = base?.presentedViewController {
            return topViewController(base: presented)
        } else {
            return base
        }
    }

    class func rootViewController() -> UIViewController? {
        let windowScene = UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .first { $0.activationState == .foregroundActive } ?? UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .first

        let keyWindow = windowScene?.windows.first(where: { $0.isKeyWindow }) ?? UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .flatMap { $0.windows }
            .first(where: { $0.isKeyWindow })

        return keyWindow?.rootViewController
    }

}
