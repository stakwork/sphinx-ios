//
//  NewMessageBubbleHelper.swift
//  sphinx
//
//  Created by Tomas Timinskas on 23/12/2019.
//  Copyright © 2019 Sphinx. All rights reserved.
//

import UIKit
import KYDrawerController

class NewMessageBubbleHelper {
    
    let labelMargin: CGFloat = 10
    let bubbleMargin: CGFloat = 12
    let titleLabelHeight: CGFloat = 20
    let titleLabelBottomMargin: CGFloat = 5
    
    var rootViewController : RootViewController?
    
    let font = UIFont(name: "Roboto-Regular", size: 13.0)!
    let titleFont = UIFont(name: "Roboto-Bold", size: 15.0)!
    let loadingWheelSize: CGFloat = 50.0
    var genericMessageY: CGFloat = 120.0
    
    var urlRanges = [NSRange]()
    
    static let messageViewTag = -1
    static let loadingViewTag = -2
    
    func showAudioTooltip(y: CGFloat, delay: Double = 2.0) {
        let screenSize = WindowsManager.getWindowSize()
        let tooltipHeight: CGFloat = 60
        let yPosition = y - tooltipHeight
        let tooltip = AudioRecordingTooltip(frame: CGRect(x: 0.0, y: yPosition, width: screenSize.width, height: tooltipHeight))
        tooltip.tag = NewMessageBubbleHelper.messageViewTag
        
        let tap = TouchUpGestureRecognizer(target: self, action: #selector(self.handleTap(_:)))
        tooltip.addGestureRecognizer(tap)
        
        toggleGenericBubbleView(view: tooltip, show: true)
        
        DelayPerformedHelper.performAfterDelay(seconds: delay) {
            self.toggleGenericBubbleView(view: tooltip, show: false)
        }
    }
    
    func showGenericMessageView(
        text: String,
        delay: Double = 1.5,
        textColor: UIColor = UIColor.Sphinx.Body,
        backColor: UIColor = UIColor.Sphinx.Text,
        backAlpha: CGFloat = 0.7
    ) {
        if GroupsPinManager.sharedInstance.shouldAskForPin() {
            return
        }
        
        let messageLabel = getGenericMessageLabel(text: text, textColor: textColor)
        let view = getGenericMessageBubbleView(label: messageLabel, backColor: backColor, backAlpha: backAlpha)
        view.addSubview(messageLabel)
        view.alpha = 0.0
        view.tag = NewMessageBubbleHelper.messageViewTag
        
        toggleGenericBubbleView(view: view, show: true)
        
        DelayPerformedHelper.performAfterDelay(seconds: delay) {
            self.toggleGenericBubbleView(view: view, show: false)
        }
    }
    
    func showLoadingWheel(
        text: String? = nil,
        textColor: UIColor = UIColor.Sphinx.Body,
        backColor: UIColor = UIColor.Sphinx.Text,
        backAlpha: CGFloat = 0.8
    ) {
        if GroupsPinManager.sharedInstance.shouldAskForPin() {
            return
        }
        
        var label: UILabel? = nil
        
        if let text = text {
            label = getGenericMessageLabel(text: text, textColor: textColor)
            label?.frame.origin.y = loadingWheelSize
            label?.textAlignment = .center
        }
        let view = getGenericMessageBubbleView(label: label, backColor: backColor, backAlpha: backAlpha, hasWheel: true)
        
        if let label = label {
            view.addSubview(label)
        }
        
        let loadingWheel = UIActivityIndicatorView(frame: CGRect(x: (view.frame.size.width / 2 - loadingWheelSize / 2), y: 0, width: loadingWheelSize, height: loadingWheelSize))
        loadingWheel.color = UIColor.Sphinx.Body
        loadingWheel.startAnimating()
        
        view.addSubview(loadingWheel)
        view.alpha = 0.0
        view.tag = NewMessageBubbleHelper.loadingViewTag
        
        if let window = UIApplication.shared.windows.first {
            window.isUserInteractionEnabled = false
            self.toggleGenericBubbleView(view: view, show: true, tag: NewMessageBubbleHelper.loadingViewTag)
        }
    }
    
    func hideLoadingWheel() {
        hideBubbleWith(tag: NewMessageBubbleHelper.loadingViewTag)
    }
    
    func hideGenericMessage() {
        hideBubbleWith(tag: NewMessageBubbleHelper.messageViewTag)
    }
    
    func hideBubbleWith(tag: Int) {
        if let window = UIApplication.shared.windows.first {
            window.isUserInteractionEnabled = true
            
            for v in window.subviews {
                if v.tag == tag {
                    UIView.animate(withDuration: 0.1, animations: {
                        v.alpha = 0.0
                    }, completion: { _ in
                        v.removeFromSuperview()
                    })
                }
            }
        }
    }
    
    func toggleGenericBubbleView(
        view: UIView,
        show: Bool,
        tag: Int = NewMessageBubbleHelper.messageViewTag
    ) {
        if let window = UIApplication.shared.windows.first {
            if show {
                for v in window.subviews {
                    if v.tag == tag {
                        v.removeFromSuperview()
                        
                        window.addSubview(view)
                        view.alpha = 1.0
                        
                        return
                    }
                }
                
                window.addSubview(view)
            }
            
            UIView.animate(withDuration: 0.1, animations: {
                view.alpha = show ? 1.0 : 0.0
            }, completion: { _ in
                if !show {
                    view.removeFromSuperview()
                }
            })
        }
    }
    
    func getGenericMessageBubbleView(
        label: UILabel? = nil,
        backColor: UIColor = UIColor.Sphinx.Text,
        backAlpha: CGFloat = 0.8, hasWheel: Bool = false
    ) -> UIView {
        let screenSize = WindowsManager.getWindowSize()
        var viewWidth = hasWheel ? loadingWheelSize : 0.0
        var viewHeight = hasWheel ? loadingWheelSize : 0.0
        
        if let label = label {
            let labelWidth = label.frame.size.width + (labelMargin * 2)
            viewWidth = (viewWidth > labelWidth) ? viewWidth : labelWidth
            viewHeight += label.frame.size.height + (labelMargin * 2)
        }
        
        let x = (screenSize.width - viewWidth) / 2
        let y = hasWheel ? (screenSize.height - viewHeight) / 2 : genericMessageY

        let v = UIView(frame: CGRect(x: x, y: y, width: viewWidth, height: viewHeight))
        v.backgroundColor = backColor.withAlphaComponent(backAlpha)
        v.layer.cornerRadius = 5
        v.addShadow(offset: CGSize(width: 0, height: 0), radius: 3.0)
        
        if !hasWheel {
            let tap = TouchUpGestureRecognizer(target: self, action: #selector(self.handleTap(_:)))
            v.addGestureRecognizer(tap)
        }
        
        return v
    }
    
    func getGenericMessageLabel(
        text: String,
        textColor: UIColor = UIColor.Sphinx.Body
    ) -> UILabel {
        let screenSize = WindowsManager.getWindowSize()
        let labelSize = getLabelSize(text: text, font: font, screenSize: screenSize)
        let label = UILabel(frame: CGRect(x: labelMargin, y: labelMargin, width: labelSize.width, height: labelSize.height))
        label.font = font
        label.textColor = textColor
        label.text = text
        label.numberOfLines = 0
        label.textAlignment = .center
        
        addLinksOn(label, color: textColor)
        
        return label
    }
    
    func addLinksOn(
        _ label: UILabel,
        color: UIColor
    ) {
        urlRanges = label.addLinksOnLabel(linkColor: color)
        
        if urlRanges.count > 0 {
            let tap = UITapGestureRecognizer(target: self, action: #selector(labelTapped(gesture:)))
            label.addGestureRecognizer(tap)
        }
    }
    
    @objc func labelTapped(gesture: UITapGestureRecognizer) {
        if let label = gesture.view as? UILabel, let text = label.text {
            for range in urlRanges {
                if gesture.didTapAttributedTextInLabel(label, inRange: range) {
                    var link = (text as NSString).substring(with: range)
                    
                    if link.stringLinks.count > 0 {
                        if !link.contains("http") {
                            link = "http://\(link)"
                        }
                        UIApplication.shared.open(URL(string: link)!, options: [:], completionHandler: nil)
                    }
                }
            }
        }
    }
    
    func showMessageView(
        title: String,
        text: String,
        chatId: Int? = nil,
        delay: Double = 2.5,
        onKeyWindow: Bool = true,
        isNewMessage: Bool = false
    ) {
        if let window = UIApplication.shared.windows.first {
            
            if let rootVC = (window.rootViewController as? RootViewController), isNewMessage {
                if rootVC.isDashboardVC() {
                    return
                }
                
                if let vcChatId = rootVC.getChatVCId(), vcChatId == chatId {
                    return
                }
            }
            
            let screenSize = WindowsManager.getWindowSize()
            let titleLabel = getTitleLabel(title: title, screenSize: screenSize)
            let messageLabel = getMessageLabel(text: text, screenSize: screenSize)
            let v = getBubbleView(label: messageLabel, chatId: chatId)
            
            v.addSubview(titleLabel)
            v.addSubview(messageLabel)
            
            window.addSubview(v)
            
            toggleBubbleView(view: v, show: true)
            
            DelayPerformedHelper.performAfterDelay(seconds: delay) {
                self.toggleBubbleView(view: v, show: false)
            }
        }
    }
    
    func showMessageView(
        message: TransactionMessage,
        delay: Double = 2.5,
        onKeyWindow: Bool = true
    ) {
        let contactsService = ContactsService.sharedInstance
        
        guard let owner = contactsService.owner else {
            return
        }
        
        let chatName = message.chat?.name ?? ""
        let sender = contactsService.getContactWith(id: message.senderId)
        
        let text = message.getMessageContentPreview(
            owner: owner,
            contact: sender
        )
        
        if text.isNotSupportedMessage { return }
        
        let senderNickname = message.getMessageSenderNickname(
            owner: owner,
            contact: sender
        )
        
        let bubbleTitle = (chatName != "") ? "\(senderNickname) on \(chatName)" : senderNickname
        
        if let chat = message.chat {
            showMessageView(
                title: bubbleTitle,
                text: text,
                chatId: chat.id,
                delay: delay,
                onKeyWindow: onKeyWindow,
                isNewMessage: true
            )
        }
    }
    
    func toggleBubbleView(
        view: UIView,
        show: Bool,
        animated: Bool = true
    ) {
        let windowInsets = getWindowInsets()
        
        if !animated {
            view.frame.origin.y = show ? windowInsets.top : -view.frame.size.height
            if !show {
                view.removeFromSuperview()
            }
        } else {
            UIView.animate(withDuration: 0.1, animations: {
                view.frame.origin.y = show ? windowInsets.top : -view.frame.size.height
            }, completion: { _ in
                if !show {
                    view.removeFromSuperview()
                }
            })
        }
    }
    
    func getBubbleView(
        label: UILabel,
        chatId: Int? = nil
    ) -> UIView {
        let viewWidth = label.frame.size.width + (labelMargin * 2)
        let viewHeight = label.frame.size.height + (labelMargin * 2) + titleLabelHeight + titleLabelBottomMargin
        let v = UIView(frame: CGRect(x: bubbleMargin, y: -viewHeight, width: viewWidth, height: viewHeight))
        v.backgroundColor = UIColor.Sphinx.PrimaryBlue
        v.layer.cornerRadius = 5
        v.addShadow(offset: CGSize(width: 0, height: 0), radius: 3.0)
        
        if let chatId = chatId {
            v.tag = chatId
        }
        
        let tap = TouchUpGestureRecognizer(target: self, action: #selector(self.handleTap(_:)))
        v.addGestureRecognizer(tap)
        
        let swipeUp = UISwipeGestureRecognizer(target: self, action: #selector(self.handleSwipe(_:)))
        swipeUp.direction = .up
        v.addGestureRecognizer(swipeUp)
        
        return v
    }
    
    func getTitleLabel(
        title: String,
        screenSize: CGSize
    ) -> UILabel {
        let labelWidth = screenSize.width - (bubbleMargin * 2) - (labelMargin * 2)
        let label = UILabel(frame: CGRect(x: labelMargin, y: labelMargin, width: labelWidth, height: titleLabelHeight))
        label.font = titleFont
        label.textColor = UIColor.white
        label.text = title
        label.numberOfLines = 0
        return label
    }
    
    func getMessageLabel(
        text: String,
        screenSize: CGSize
    ) -> UILabel {
        let labelSize = getLabelSize(text: text, font: font, screenSize: screenSize)
        let labelWidth = screenSize.width - (bubbleMargin * 2) - (labelMargin * 2)
        let label = UILabel(frame: CGRect(x: labelMargin, y: labelMargin + titleLabelHeight + titleLabelBottomMargin, width: labelWidth, height: labelSize.height))
        label.font = font
        label.textColor = UIColor.white
        label.text = text
        label.numberOfLines = 0
        return label
    }
    
    func getLabelSize(
        text: String,
        font: UIFont,
        screenSize: CGSize
    ) -> CGRect {
        
        let screenWidth = screenSize.width
        let labelWidth = screenWidth - (bubbleMargin * 2) - (labelMargin * 2)
        let constraintRect = CGSize(width: labelWidth, height: .greatestFiniteMagnitude)
        
        let boundingBox = text.boundingRect(with: constraintRect,
                                            options: .usesLineFragmentOrigin,
                                            attributes: [.font: font],
                                            context: nil)
        
        return boundingBox
    }
    
    @objc func handleTap(_ sender: TouchUpGestureRecognizer? = nil) {
        if let view = sender?.view {
            toggleBubbleView(view: view, show: false, animated: false)
            
            if view.tag > 0 {
                goToChat(chatId: view.tag)
            }
        }
    }
    
    @objc func handleSwipe(_ sender: UISwipeGestureRecognizer? = nil) {
        if let view = sender?.view, view.tag > 0 {
            toggleBubbleView(view: view, show: false)
        }
    }
    
    func goToChat(chatId: Int) {
        if let chat = Chat.getChatWith(id: chatId) {
            
            let chatVC = NewChatViewController.instantiate(
                contactId: chat.conversationContact?.id,
                chatId: chat.id
            )
            
            if
                let appDelegate = UIApplication.shared.delegate as? AppDelegate,
                let rootVC = appDelegate.getRootViewController(),
                let navCenterController = rootVC.getCenterNavigationController()
            {
                navCenterController.viewControllers.last?.view.endEditing(true)
                navCenterController.pushViewController(chatVC, animated: true)
            }
        }
    }
}
