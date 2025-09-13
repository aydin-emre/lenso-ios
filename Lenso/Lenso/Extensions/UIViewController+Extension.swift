//
//  UIViewController+Extension.swift
//  Lenso
//
//  Created by Emre on 13.09.2025.
//

import UIKit
import SwiftUI

extension UIViewController {

    func addSwiftUIView<T: View>(into view: UIView, _ swiftUIView: T) {
        let hostingController = UIHostingController(rootView: swiftUIView)
        hostingController.overrideUserInterfaceStyle = .dark
        addChild(hostingController)
        view.addSubview(hostingController.view)
        hostingController.view.backgroundColor = .clear
        hostingController.didMove(toParent: self)
        hostingController.view.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            hostingController.view.topAnchor.constraint(equalTo: view.topAnchor),
            hostingController.view.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            hostingController.view.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            hostingController.view.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }

}
