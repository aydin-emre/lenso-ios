//
//  StoryboardInstantiable.swift
//  Lenso
//
//  Created by Emre on 13.09.2025.
//

import UIKit

protocol StoryboardInstantiable {
    static var storyboard: Storyboard { get }
    static func instantiate(_ bundle: Bundle?) -> Self
}

extension StoryboardInstantiable where Self: UIViewController {

    static func instantiate(_ bundle: Bundle? = nil) -> Self {
        return UIStoryboard(name: storyboard.rawValue, bundle: bundle)
            .instantiateViewController(withIdentifier: String(describing: self)) as! Self
    }

}
