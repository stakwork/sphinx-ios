//
//  UICollectionView.swift
//  sphinx
//
//  Created by Tomas Timinskas on 07/01/2020.
//  Copyright © 2020 Sphinx. All rights reserved.
//

import UIKit

extension UICollectionView {
    func registerCell(_ type: UICollectionViewCell.Type) {
        register(UINib(nibName: String(describing: type), bundle: Bundle.main), forCellWithReuseIdentifier: String(describing: type))
    }

    func dequeueCellForIndexPath<T: UICollectionViewCell>(_ indexPath: IndexPath) -> T {
        guard let cell = dequeueReusableCell(withReuseIdentifier: String(describing: T.self), for: indexPath) as? T else {
            fatalError("\(String(describing: T.self)) cell could not be instantiated because it was not found on the tableView")
        }
        return cell
    }
}
