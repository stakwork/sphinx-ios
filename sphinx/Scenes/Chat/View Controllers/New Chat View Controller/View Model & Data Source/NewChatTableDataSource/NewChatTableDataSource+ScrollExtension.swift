//
//  NewChatTableDataSource+ScrollExtension.swift
//  sphinx
//
//  Created by Tomas Timinskas on 13/06/2023.
//  Copyright © 2023 sphinx. All rights reserved.
//

import UIKit

extension NewChatTableDataSource: UITableViewDelegate {
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        let difference: CGFloat = 16
        let scrolledToTop = tableView.contentOffset.y > tableView.contentSize.height - tableView.frame.size.height - difference
        let scrolledToBottom = tableView.contentOffset.y < -10
        let didMoveOutOfBottomArea = tableView.contentOffset.y > -10
                
        if scrolledToTop {
            didScrollToTop()
        } else if scrolledToBottom {
            didScrollToBottom()
        } else if didMoveOutOfBottomArea {
            didScrollOutOfBottomArea()
        }
    }
    
    func scrollViewShouldScrollToTop(_ scrollView: UIScrollView) -> Bool {
        return false
    }
    
    func didScrollOutOfBottomArea() {
        scrolledAtBottom = false
        
        delegate?.didScrollOutOfBottomArea()
    }
    
    func didScrollToBottom() {
        if scrolledAtBottom {
            return
        }
        
        scrolledAtBottom = true
        
        delegate?.didScrollToBottom()
    }
    
    func didScrollToTop() {
        if loadingMoreItems {
            return
        }
        
        loadingMoreItems = true
        
        loadMoreItems()
    }
    
    func loadMoreItems() {
        DelayPerformedHelper.performAfterDelay(seconds: 0.5, completion: { [weak self] in
            guard let self = self else { return }
            self.configureResultsController(items: self.dataSource.snapshot().numberOfItems + 50)
        })
    }
}
