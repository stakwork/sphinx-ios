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
                
        if tableView.contentOffset.y > tableView.contentSize.height - tableView.frame.size.height - difference {
            loadMoreItems()
        } else if tableView.contentOffset.y < difference {
            print("SCROLL TO BOTTOM")
        }
    }
    
    func loadMoreItems() {
        if loadingMoreItems {
            return
        }
        
        loadingMoreItems = true
        
        DelayPerformedHelper.performAfterDelay(seconds: 0.5, completion: { [weak self] in
            guard let self = self else { return }
            self.configureResultsController(items: self.dataSource.snapshot().numberOfItems + 50)
        })
    }
}
