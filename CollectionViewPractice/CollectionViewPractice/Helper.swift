//
//  Helper.swift
//  CollectionViewPractice
//
//  Created by Macbook on 2/24/24.
//

import Foundation
import UIKit

protocol ReuseIdentifiable {
    static var reuseIdentifier : String { get }
}

extension ReuseIdentifiable {
    static var reuseIdentifier : String {
        return String(describing: Self.self)
    }
}

extension UICollectionViewCell : ReuseIdentifiable { }

extension UICollectionReusableView : ReuseIdentifiable { }
