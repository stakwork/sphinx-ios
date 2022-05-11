//
//  MessageWebViewTableViewCell.swift
//  sphinx
//
//  Created by Tomas Timinskas on 16/09/2020.
//  Copyright © 2020 Sphinx. All rights reserved.
//

import UIKit
import WebKit

class MessageWebViewTableViewCell: CommonReplyTableViewCell, MessageRowProtocol {
    
    @IBOutlet weak var bubbleView: MessageBubbleView!
    @IBOutlet weak var lockSign: UILabel!
    @IBOutlet weak var bubbleWidth: NSLayoutConstraint!
    @IBOutlet weak var webView: BotWebView!
    @IBOutlet weak var loadingWheel: UIActivityIndicatorView!
    
    @IBOutlet weak var webViewTopMargin: NSLayoutConstraint!
    @IBOutlet weak var webViewLeftMargin: NSLayoutConstraint!
    @IBOutlet weak var webViewBottomMargin: NSLayoutConstraint!
    @IBOutlet weak var webViewRightMargin: NSLayoutConstraint!
    
    public static let kMessageWebViewRowHeight: CGFloat = 60
    public static let kMessageWebViewBubbleWidth: CGFloat = 200
    
    let kWebViewContentPrefix = "<head><meta name=\"viewport\" content=\"width=device-width, height=device-height, shrink-to-fit=YES\"></head><body style=\"font-family: 'Roboto', sans-serif; color: %@; margin:0px !important; padding:0px!important; background: %@;\"><div id=\"bot-response-container\" style=\"background: %@;\">"
    let kWebViewContentSuffix = "</div></body>"
    
    let kDocumentReadyJSCommand = "document.readyState"
    let kGetContainerJSCommand = "document.getElementById(\"bot-response-container\").clientHeight"
    
    var loading = false {
        didSet {
            webView.alpha = loading ? 0.0 : 1.0
            LoadingWheelHelper.toggleLoadingWheel(loading: loading, loadingWheel: loadingWheel, loadingWheelColor: UIColor.Sphinx.Text)
        }
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        loading = false
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
    }
    
    func configureMessageRow(messageRow: TransactionMessageRow, contact: UserContact?, chat: Chat?) {
        super.configureRow(messageRow: messageRow, contact: contact, chat: chat)

        let bubbleSize = bubbleView.showIncomingMessageWebViewBubble(messageRow: messageRow)
        setBubbleWidth(bubbleSize: bubbleSize)
        configureReplyBubble(bubbleView: bubbleView, bubbleSize: bubbleSize, incoming: true)
        
        commonConfigurationForMessages()
        lockSign.text = messageRow.transactionMessage.encrypted ? "lock" : ""

        if messageRow.shouldShowRightLine {
            addRightLine()
        }

        if messageRow.shouldShowLeftLine {
            addLeftLine()
        }
        
        setWebViewMargins()
        setWebViewContent()
    }
    
    func setWebViewMargins() {
        if webViewTopMargin.constant != Constants.kLabelMargins {
            webViewTopMargin.constant = Constants.kLabelMargins
            webViewBottomMargin.constant = Constants.kLabelMargins
            webViewRightMargin.constant = Constants.kLabelMargins
            webViewLeftMargin.constant = Constants.kLabelMargins + Constants.kBubbleReceivedArrowMargin
            webView.superview?.layoutIfNeeded()
        }
    }
    
    func setWebViewContent() {
        webView.navigationDelegate = self
        webView.isUserInteractionEnabled = false
        webView.scrollView.isScrollEnabled = false
        webView.scrollView.contentInsetAdjustmentBehavior = .never
        
        let backgroundColor = UIColor(cgColor: UIColor.Sphinx.OldReceivedMsgBG.resolvedCGColor(with: self.contentView)).toHexString()
        let textColor = UIColor(cgColor: UIColor.Sphinx.Text.resolvedCGColor(with: self.contentView)).toHexString()
        
        let contentPrefix = String(format: kWebViewContentPrefix, textColor, backgroundColor, backgroundColor)
        let messageContent = messageRow?.transactionMessage.messageContent ?? ""
        let content = "\(contentPrefix)\(messageContent)\(kWebViewContentSuffix)"
        
        let webViewHeight = messageRow?.transactionMessage.getWebViewHeight()
        if content != webView.contentString || webViewHeight == nil {
            loading = true
            let _ = webView.loadHTMLString(content, baseURL: Bundle.main.bundleURL)
        } else {
            hideLoadingWheel(withDelay: 0.2)
        }
    }
    
    func hideLoadingWheel(withDelay delay: Double) {
        DelayPerformedHelper.performAfterDelay(seconds: delay, completion: {
            self.loading = false
        })
    }
    
    func setBubbleWidth(bubbleSize: CGSize) {
        bubbleWidth.constant = bubbleSize.width
        bubbleView.superview?.layoutIfNeeded()
        bubbleView.layoutIfNeeded()
    }
    
    public static func getRowHeight(messageRow: TransactionMessageRow) -> CGFloat {
        let webViewHeight = messageRow.transactionMessage.getWebViewHeight() ?? kMessageWebViewRowHeight
        let replyTopPading = CommonChatTableViewCell.getReplyTopPadding(message: messageRow.transactionMessage)
       return webViewHeight + replyTopPading + (Constants.kLabelMargins * 2) + CommonChatTableViewCell.kBubbleTopMargin + CommonChatTableViewCell.kBubbleBottomMargin
    }
}

extension MessageWebViewTableViewCell : WKNavigationDelegate {
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        if let webViewHeight = messageRow?.transactionMessage.getWebViewHeight() {
            self.webView.frame.size.height = webViewHeight
            
            hideLoadingWheel(withDelay: 0.2)
        } else {
            webView.evaluateJavaScript(self.kDocumentReadyJSCommand, completionHandler: { (complete, error) in
                if complete == nil {
                    return
                }
                
                webView.evaluateJavaScript(self.kGetContainerJSCommand, completionHandler: { (height, error) in
                    let height = ((height as? CGFloat) ?? MessageWebViewTableViewCell.kMessageWebViewRowHeight) + 10
                    self.messageRow?.transactionMessage.save(webViewHeight: height)
                    self.webView.frame.size.height = height
                    self.reloadRowOnLoadFinished()
                })
            })
        }
    }
    
    func reloadRowOnLoadFinished() {
        self.delegate?.shouldReloadCell?(cell: self)
        
        DelayPerformedHelper.performAfterDelay(seconds: 0.5, completion: {
            self.delegate?.shouldScrollToBottom()
        })
    }
}
