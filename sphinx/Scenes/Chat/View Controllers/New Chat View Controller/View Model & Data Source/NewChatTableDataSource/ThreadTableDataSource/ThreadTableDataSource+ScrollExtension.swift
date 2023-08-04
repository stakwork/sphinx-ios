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
        
        let headerHeight = getHeaderHeight() ?? 0
        
        let scrolledToTop = tableView.contentOffset.y > tableView.contentSize.height - tableView.frame.size.height - headerHeight
        let didMoveOutOfTop = tableView.contentOffset.y < tableView.contentSize.height - tableView.frame.size.height - headerHeight
        let scrolledToBottom = tableView.contentOffset.y < -10
        let didMoveOutOfBottom = tableView.contentOffset.y > -10
                
        if scrolledToBottom {
            didScrollToBottom()
        }
        
        if scrolledToTop {
            didScrollToTop()
        }
        
        if didMoveOutOfTop {
            didMoveOutOfTopArea()
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
        
        delegate?.didScroll()
    }
    
    override func didMoveOutOfBottomArea() {
        scrolledAtBottom = false

        delegate?.didScrollOutOfBottomArea()
    }
    
    func didMoveOutOfTopArea() {
        delegate?.shouldToggleThreadHeader(expanded: true)
    }
    
    override func didScrollToBottom() {
        if scrolledAtBottom {
            return
        }
        
        scrolledAtBottom = true
        
        delegate?.didScrollToBottom()
    }
    
    override func didScrollToTop() {
        delegate?.shouldToggleThreadHeader(expanded: false)
    }
}
