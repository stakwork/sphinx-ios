//
//  ThreadTableDataSource+ScrollExtension.swift
//  sphinx
//
//  Created by Tomas Timinskas on 03/08/2023.
//  Copyright © 2023 sphinx. All rights reserved.
//

import UIKit

extension ThreadTableDataSource {
    
    override func scrollViewDidScroll(_ scrollView: UIScrollView) {
        if tableView.contentSize.height <= 0 {
            return
        }
        
        let scrolledToBottom = tableView.contentOffset.y < -10
        let didMoveOutOfBottom = tableView.contentOffset.y > -10
                
        if scrolledToBottom {
            didScrollToBottom()
        }
        
        if didMoveOutOfBottom {
            didMoveOutOfBottomArea()
        }
        
        if let lastVisibleRow = tableView.indexPathsForVisibleRows?.last?.row {
            if lastVisibleRow < messageTableCellStateArray.count - 1 {
                ///Collapse header message when it scrolls out of boundaries
                shouldCollapseHeaderMessage()
            }
        }
        
        toggleHeader()
    }
    
    override func didMoveOutOfBottomArea() {
        scrolledAtBottom = false

        delegate?.didScrollOutOfBottomArea()
    }
    
    override func didScrollToBottom() {
        if scrolledAtBottom {
            return
        }
        
        scrolledAtBottom = true
        
        delegate?.didScrollToBottom()
    }
}
