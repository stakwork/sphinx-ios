//
//  MessageOptionsMenuHelper.swift
//  sphinx
//
//  Created by Tomas Timinskas on 15/06/2023.
//  Copyright © 2023 sphinx. All rights reserved.
//

import UIKit

class MessageOptionsMenuHelper {
    
    func getMessageBubbleRectAndPath(
        tableView: UITableView,
        indexPath: IndexPath,
        contentView: UIView,
        bubbleViewRect: CGRect
    ) -> (CGRect, CGPath)? {
        
        if let cell = tableView.cellForRow(at: indexPath) {
            let cellRectInTable = tableView.rectForRow(at: indexPath)
            let cellOffset = tableView.convert(cellRectInTable.origin, to: contentView)
            let cellFrame = cell.frame
        
            let cellY = cellOffset.y - cellFrame.height
        
            let bubbleRect = CGRect(
                x: bubbleViewRect.origin.x,
                y: cellY + bubbleViewRect.origin.y,
                width: bubbleViewRect.size.width,
                height: bubbleViewRect.size.height
            )
            
            return (
                bubbleRect,
                UIBezierPath(
                    roundedRect: CGRect(origin: CGPoint.zero, size: bubbleRect.size),
                    cornerRadius: 8
                ).cgPath
            )
        }
        
        return nil
    }
}
