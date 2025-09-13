//
//  Router.swift
//  Lenso
//
//  Created by Emre on 13.09.2025.
//

import UIKit

class Router: NSObject {

    static func pushViewController(_ viewController: UIViewController, animated: Bool = true) {
        presentedViewController.navigationController?.pushViewController(viewController, animated: animated)
    }

    static func presentViewController(_ viewController: UIViewController,
                                      modalPresentationStyle: UIModalPresentationStyle = .fullScreen,
                                      animated: Bool = true,
                                      completion: (() -> Void)? = nil) {
        let nav = UINavigationController.init(rootViewController: viewController)
        nav.modalPresentationStyle = modalPresentationStyle
        presentedViewController.present(nav, animated: animated, completion: completion)
    }

    private static var presentedViewController: UIViewController {
        return UIApplication.topViewController()!
    }

}
