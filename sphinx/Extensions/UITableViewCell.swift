//
//  UITableViewCell.swift
//  sphinx
//
//  Created by Tomas Timinskas on 11/04/2020.
//  Copyright © 2020 Sphinx. All rights reserved.
//

import UIKit

extension UITableViewCell {
    func isCompletelyVisible(tableView: UITableView) -> Bool {
        if let indexPath = tableView.indexPath(for: self) {
            let cellRect = tableView.rectForRow(at: indexPath)
            let completelyVisible = tableView.bounds.contains(cellRect)
            return completelyVisible
        }
        return false
    }
}
