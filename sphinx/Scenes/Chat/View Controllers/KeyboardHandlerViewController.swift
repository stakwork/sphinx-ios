//
//  Library
//
//  Created by Tomas Timinskas on 01/03/2019.
//  Copyright © 2019 Sphinx. All rights reserved.
//

import UIKit

class KeyboardHandlerViewController: OrientationHandlerViewController {
    
    @IBOutlet weak var chatTableView: UITableView!
    @IBOutlet weak var scrollDownContainer: UIView!
    @IBOutlet weak var scrollDownViewBottomConstraint: NSLayoutConstraint!
    @IBOutlet weak var mentionAutoCompleteTableView: UITableView!
    @IBOutlet weak var pinnedMessageView: PinnedMessageView!

    let windowInsets = getWindowInsets()
    let kSmallHeaderHeight: CGFloat = 55
    var kLargeHeaderHeight: CGFloat = 145
    let kHeaderHeight: CGFloat = 65
    let kHeaderPinHeight: CGFloat = 50
    var bottomContentInset : CGFloat = ChatAccessoryView.kTableBottomPadding

    let accessoryView = ChatAccessoryView(frame: CGRect(x: 0, y: 0, width: WindowsManager.getWindowWidth(), height: ChatAccessoryView.kAccessoryViewDefaultHeight))
    
    static var keyboardVisible = false
    
    override var inputAccessoryView: ChatAccessoryView {
        return accessoryView
    }
         
    override var canBecomeFirstResponder: Bool { return true }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        let bottomBarHeight = accessoryView.viewContentSize().height + ChatAccessoryView.kTableBottomPadding + windowInsets.bottom
        adjustScrollDownView(height: bottomBarHeight, animated: false)
        setTableInset(bottomBarHeight: bottomBarHeight)
    }
    
    func keyboardWillShowHandler(_ notification: Notification, tableView: UITableView) {
        adjustContentForKeyboard(shown: true, notification: notification)
    }
    
    func keyboardWillHideHandler(_ notification: Notification, tableView: UITableView) {
        adjustContentForKeyboard(shown: false, notification: notification)
    }
    
    func getKeyboardActualHeight(notification: Notification) -> CGFloat? {
        if let keyboardEndSize = (notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue {
            let keyboardHeight = WindowsManager.getWindowHeight() - keyboardEndSize.origin.y + ChatAccessoryView.kTableBottomPadding
            return keyboardHeight
        }
        return nil
    }
    
    func adjustContentForKeyboard(shown: Bool, notification: Notification) {
        if var keyboardHeight = getKeyboardActualHeight(notification: notification), keyboardHeight > 0 {
            let bottomBarHeight = accessoryView.viewContentSize().height + ChatAccessoryView.kTableBottomPadding + windowInsets.bottom
            let showing = shown && keyboardHeight != bottomBarHeight
            keyboardHeight = max(keyboardHeight, bottomBarHeight)
            
            let animationDuration:Double = KeyboardHelper.getKeyboardAnimationDuration(notification: notification)
            let animationCurve:Int = KeyboardHelper.getKeyboardAnimationCurve(notification: notification)
            let distanceFromBottom = bottomOffset().y - chatTableView.contentOffset.y
        
            bottomContentInset = keyboardHeight
            
            if shown {
                NotificationCenter.default.post(name: .onKeyboardShown, object: nil)
            }
            
            KeyboardHandlerViewController.keyboardVisible = showing
            
            if chatTableView.contentInset.bottom == keyboardHeight {
                if distanceFromBottom < 50 { self.chatTableView.contentOffset = self.bottomOffset() }
                return
            }
            
            UIView.animate(withDuration: animationDuration, delay: 0, options: UIView.AnimationOptions(rawValue: UIView.AnimationOptions.RawValue(animationCurve)), animations: {
        
                self.adjustScrollDownView(height: keyboardHeight, animated: showing)
                self.setTableInset(bottomBarHeight: keyboardHeight)
                
                if distanceFromBottom < 50 { self.chatTableView.contentOffset = self.bottomOffset() }
            }, completion: { _ in
                if distanceFromBottom < 100 { self.chatTableView.scrollToBottom() }
            })
        }
    }
    
    func addBottomInset(height: CGFloat) {
        if height > 0 {
            setTableInset(bottomBarHeight: chatTableView.contentInset.bottom + height)
            adjustScrollDownView(height: chatTableView.contentInset.bottom + height, animated: false)
        }
    }
    
    func setTableInset(bottomBarHeight: CGFloat) {
        bottomContentInset = bottomBarHeight
        chatTableView.contentInset.bottom = bottomContentInset
        chatTableView.verticalScrollIndicatorInsets.bottom = bottomContentInset
        mentionAutoCompleteTableView.contentInset.top = bottomContentInset - ChatAccessoryView.kTableBottomPadding
        setTopInset()
    }
    
    func setTopInset() {
        let addPinMessageHeight = !pinnedMessageView.isHidden
        let headerHeight = windowInsets.top + kHeaderHeight + (addPinMessageHeight ? kHeaderPinHeight : 0)
        chatTableView.contentInset.top = headerHeight
        chatTableView.verticalScrollIndicatorInsets.top = headerHeight
    }
    
    func adjustScrollDownView(height: CGFloat, animated: Bool) {
        scrollDownViewBottomConstraint.constant = height + 20
        
        if animated {
            scrollDownContainer.superview?.layoutIfNeeded()
        } else {
            scrollDownContainer.layoutIfNeeded()
        }
    }
    
    func scrollChatToBottom(animated: Bool = true) {
        let headerHeight = windowInsets.top + kHeaderHeight
        chatTableView?.contentInset = UIEdgeInsets.init(top: headerHeight, left: 0, bottom: bottomContentInset, right: 0)
        
        if animated {
            chatTableView?.scrollToBottom(animated: animated)
        } else {
            chatTableView?.contentOffset.y = CGFloat.greatestFiniteMagnitude
        }
    }
     
    func bottomOffset() -> CGPoint {
        return CGPoint(x: 0, y: max(-chatTableView.contentInset.top, chatTableView.contentSize.height - (chatTableView.bounds.size.height - chatTableView.contentInset.bottom)))
    }
    
    func configureReplayToMessage(message: TransactionMessage) {
        accessoryView.configureReplyFor(message: message)
    }
}
