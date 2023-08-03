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
        let headerHeight = self.threadHeaderHeight ?? 0
        
        let difference: CGFloat = 16
        let scrolledToBottom = tableView.contentOffset.y > tableView.contentSize.height - tableView.frame.size.height - difference
        let scrolledToTop = tableView.contentOffset.y < headerHeight
        let didMoveOutOfTop = tableView.contentOffset.y > headerHeight
        let didMoveOutOfBottom = tableView.contentOffset.y < tableView.contentSize.height - tableView.frame.size.height + difference
                
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
        
        shouldCollapseHeader()
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
