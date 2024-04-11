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
        let y = self.contentOffset.y
        let contentHeight = (self.contentSize.height - self.frame.size.height + self.contentInset.bottom)
        let difference = contentHeight - y
        
        if difference <= 50 {
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
            if self.numberOfSections == 0 {
                return
            }
            
            self.scrollToRow(
                index: self.numberOfRows(inSection:  self.numberOfSections - 1) - 1,
                animated: animated
            )
        }
    }
    
    func scrollToTop(animated: Bool = true){
        DispatchQueue.main.async {
            if self.numberOfSections == 0 {
                return
            }
            
            self.scrollToRow(
                index: 0,
                animated: animated
            )
        }
    }
    
    func scrollToRow(
        index: Int,
        animated: Bool = true
    ){
        if self.numberOfRows(inSection: self.numberOfSections - 1) == 0 {
            return
        }
        
        let indexPath = IndexPath(row: index, section: self.numberOfSections - 1)
        self.scrollToRow(at: indexPath, at: .bottom, animated: animated)
    }
    
    func scrollToOffset(yPosition: CGFloat) {
        self.contentOffset.y = yPosition
    }
    
    func isCellOutOfBounds(indexPath: IndexPath) -> (Bool, Bool) {
        let cellRect = rectForRow(at: indexPath)
        
        let screenSize = UIScreen.main.bounds.size
        let contentHeightThreshold = screenSize.height - (1.1 * cellRect.size.height)
        
        if cellRect.size.height > contentHeightThreshold {
            return (false, true)
        } else if bounds.contains(cellRect) {
            return (false, false)
        } else {
            if cellRect.origin.y == 0 {
                return (false, true)
            } else {
                return (true, true)
            }
        }
    }
}

extension UIScrollView {
    func isAtBottom() -> Bool {
        let currentY = round(self.contentOffset.y)
        let bottomY = round(self.contentSize.height - self.frame.size.height + self.contentInset.bottom)
        
        return currentY == bottomY
    }
}
