//
//  ThreadTableDataSource+HeaderExtension.swift
//  sphinx
//
//  Created by Tomas Timinskas on 03/08/2023.
//  Copyright © 2023 sphinx. All rights reserved.
//

import UIKit

extension ThreadTableDataSource : ThreadHeaderTableViewCellDelegate {
    func shouldExpandHeaderMessage() {
        guard isHeaderExpanded == false else {
            return
        }
        isHeaderExpanded = true
        reloadHeaderRow()
    }
    
    func shouldCollapseHeader() {
        guard isHeaderExpanded == true else {
            return
        }
        isHeaderExpanded = false
        reloadHeaderRow()
    }
    
    func reloadHeaderRow() {
        guard let tableCellState = messageTableCellStateArray.first else {
            return
        }
        
        DispatchQueue.main.async {
            var snapshot = self.dataSource.snapshot()
            snapshot.reloadItems([tableCellState])
            self.dataSource.apply(snapshot, animatingDifferences: true)
        }
    }
}
