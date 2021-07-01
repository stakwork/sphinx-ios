//
//  UITableView.swift
//  sphinx
//
//  Created by Tomas Timinskas on 12/09/2019.
//  Copyright © 2019 Sphinx. All rights reserved.
//

import UIKit

extension UITableView {
    
    func registerCell(_ type: UITableViewCell.Type) {
        register(UINib(nibName: String(describing: type), bundle: Bundle.main), forCellReuseIdentifier: String(describing: type))
    }
    
    func dequeueCellForIndexPath<T: UITableViewCell>(_ indexPath: IndexPath) -> T {
        guard let cell = dequeueReusableCell(withIdentifier: String(describing: T.self), for: indexPath) as? T else {
            fatalError("\(String(describing: T.self)) cell could not be instantiated because it was not found on the tableView")
        }
        return cell
    }
    
    func shouldScrollToBottom() -> Bool {
        if self.contentOffset.y >= (self.contentSize.height - self.frame.size.height - 150) {
            return true
        }
        return false
    }
    
    func shouldScrollToUpdatedRowAt(indexPath: IndexPath, animated: Bool = true) {
        let diff = abs(self.rectForRow(at: indexPath).origin.y - self.contentOffset.y)
        if diff < 50 {
            self.scrollToRow(at: indexPath, at: .bottom, animated: animated)
        }
    }
    
    func scrollToBottom(animated: Bool = true){
        DispatchQueue.main.async {
            if self.numberOfRows(inSection:  self.numberOfSections - 1) == 0 {
                return
            }
            
            let indexPath = IndexPath(
                row: self.numberOfRows(inSection:  self.numberOfSections - 1) - 1,
                section: self.numberOfSections - 1)
            self.scrollToRow(at: indexPath, at: .bottom, animated: animated)
        }
    }
}
