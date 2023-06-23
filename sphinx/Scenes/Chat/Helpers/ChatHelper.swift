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
                    cornerRadius: MessageTableCellState.kBubbleCornerRadius
                ).cgPath
            )
        }
        
        return nil
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
