//
//  Library
//
//  Created by Tomas Timinskas on 01/03/2019.
//  Copyright © 2019 Sphinx. All rights reserved.
//

import UIKit

class ChatHelper {
    
    public static func getSenderColorFor(message: TransactionMessage) -> UIColor {
        var key:String? = nil
        
        if !(message.chat?.isPublicGroup() ?? false) || message.senderId == 1 {
            key = "\(message.senderId)-color"
        }
        
        if let senderAlias = message.senderAlias, !senderAlias.isEmpty {
            key = "\(senderAlias.trim())-color"
        }

        if let key = key {
            return UIColor.getColorFor(key: key)
        }
        return UIColor.Sphinx.SecondaryText
    }
    
    public static func getRecipientColorFor(
        message: TransactionMessage
    ) -> UIColor {
        if let recipientAlias = message.recipientAlias, !recipientAlias.isEmpty {
            return UIColor.getColorFor(
                key: "\(recipientAlias.trim())-color"
            )
        }
        
        return UIColor.Sphinx.SecondaryText
    }
    
    public static func getMessageBubbleRectAndPath(
        tableView: UITableView,
        indexPath: IndexPath,
        contentView: UIView,
        bubbleViewRect: CGRect
    ) -> (CGRect, CGPath)? {
        let screenSize = UIScreen.main.bounds.size
        let contentHeightThreshold = screenSize.height - (1.1 * bubbleViewRect.size.height)
        
        if let cell = tableView.cellForRow(at: indexPath) {
            let cellRectInTable = tableView.rectForRow(at: indexPath)
            let cellOffset = tableView.convert(cellRectInTable.origin, to: contentView)
            let cellFrame = cell.frame
            let cellHeight = cellFrame.height
            
            let cellY = cellOffset.y - cellHeight
            
            let contentHeight = bubbleViewRect.size.height
            
            // Check if content height exceeds the threshold
//            if contentHeight > contentHeightThreshold {
//                // Calculate the vertical position to center the bubble
//                let centerY = cellY + (cellHeight / 2) - (contentHeight / 2)
//                
//                let bubbleRect = CGRect(
//                    x: bubbleViewRect.origin.x,
//                    y: centerY - 400.0,
//                    width: bubbleViewRect.size.width,
//                    height: contentHeight
//                )
//                
//                return (
//                    bubbleRect,
//                    UIBezierPath(
//                        roundedRect: CGRect(origin: CGPoint(x: 0.0, y: -400.0), size: bubbleRect.size),
//                        cornerRadius: MessageTableCellState.kBubbleCornerRadius
//                    ).cgPath
//                )
//                
//                return (
//                    bubbleRect,
//                    UIBezierPath(
//                        roundedRect: CGRect(origin: CGPoint.zero, size: bubbleRect.size),
//                        cornerRadius: MessageTableCellState.kBubbleCornerRadius
//                    ).cgPath
//                )
//            } else {
                // Content height is within the threshold, position at the top
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
                        cornerRadius: MessageTableCellState.kBubbleCornerRadius
                    ).cgPath
                )
//            }
        }
        
        return nil
    }
    
    public static func getChatRowRectAndPath(
        collectionView: UICollectionView,
        indexPath: IndexPath,
        yOffset: CGFloat
    ) -> (CGRect, CGPath)? {
        
        if let item = collectionView.cellForItem(at: indexPath) {
            
            let itemFrame = item.frame
            
            let itemRect = CGRect(
                x: itemFrame.origin.x,
                y: itemFrame.origin.y + yOffset - collectionView.contentOffset.y,
                width: itemFrame.size.width,
                height: itemFrame.size.height
            )
            
            return (
                itemRect,
                UIBezierPath(
                    roundedRect: CGRect(origin: CGPoint.zero, size: itemRect.size),
                    cornerRadius: 0
                ).cgPath
            )
        }
        
        return nil
    }

    public static func removeDuplicatedContainedFrom(
        urlRanges: [NSRange]
    ) -> [NSRange] {
        var ranges = urlRanges
        
        var indexesToRemove: [Int] = []
        
        for (i, ur) in ranges.enumerated() {
            for urlRange in ranges {
                if (
                    ur.lowerBound >= urlRange.lowerBound && ur.upperBound < urlRange.upperBound ||
                    ur.lowerBound > urlRange.lowerBound && ur.upperBound <= urlRange.upperBound
                ) {
                    indexesToRemove.append(i)
                }
            }
        }
        
        indexesToRemove = Array(Set(indexesToRemove))
        indexesToRemove.sort(by: >)
        
        for index in indexesToRemove {
            if ranges.count > index {
                ranges.remove(at: index)
            }
        }
        
        return ranges
    }
}

func getWindowInsets() -> UIEdgeInsets {
    var insets = UIEdgeInsets(top: 20.0, left: 0.0, bottom: 0.0, right: 0.0)
    
    if let rootWindow = UIApplication.shared.windows.first {
        if #available(iOS 11.0, *) {
            if !UIApplication.shared.isSplitOrSlideOver {
                insets.top = rootWindow.safeAreaInsets.top
                insets.bottom = rootWindow.safeAreaInsets.bottom
            }
        }
    }
    return insets
}
