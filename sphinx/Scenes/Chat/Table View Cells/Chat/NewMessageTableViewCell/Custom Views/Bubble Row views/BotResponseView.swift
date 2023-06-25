//
//  BotResponseView.swift
//  sphinx
//
//  Created by Tomas Timinskas on 05/06/2023.
//  Copyright © 2023 sphinx. All rights reserved.
//

import UIKit
import WebKit

class BotResponseView: UIView {

    @IBOutlet private var contentView: UIView!
    
    @IBOutlet weak var webView: WKWebView!
    @IBOutlet weak var loadingWheel: UIActivityIndicatorView!
    
    let kWebViewContentPrefix = "<head><meta name=\"viewport\" content=\"width=device-width, height=device-height, shrink-to-fit=YES\"></head><body style=\"font-family: 'Roboto', sans-serif; color: %@; margin:0px !important; padding:0px!important; background: %@;\"><div id=\"bot-response-container\" style=\"background: %@;\">"
    let kWebViewContentSuffix = "</div></body>"
    
    let kDocumentReadyJSCommand = "document.readyState"
    let kGetContainerJSCommand = "document.getElementById(\"bot-response-container\").clientHeight"
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setup()
    }

    private func setup() {
        Bundle.main.loadNibNamed("BotResponseView", owner: self, options: nil)
        addSubview(contentView)
        contentView.frame = self.bounds
        contentView.autoresizingMask = [.flexibleHeight, .flexibleWidth]
        
        webView.isUserInteractionEnabled = false
        webView.scrollView.isScrollEnabled = false
        webView.scrollView.contentInsetAdjustmentBehavior = .never
    }
    
    func configureWith(
        botHTMLContent: BubbleMessageLayoutState.BotHTMLContent,
        botWebViewData: MessageTableCellState.BotWebViewData?
    ) {
        let loading = botWebViewData == nil
        
        loadingWheel.isHidden = !loading
        webView.isHidden = loading
        
        if !loading {
            loadingWheel.stopAnimating()
            
            let backgroundColor = UIColor(cgColor: UIColor.Sphinx.ReceivedMsgBG.resolvedCGColor(with: self)).toHexString()
            let textColor = UIColor(cgColor: UIColor.Sphinx.Text.resolvedCGColor(with: self)).toHexString()
            
            let contentPrefix = String(format: kWebViewContentPrefix, textColor, backgroundColor, backgroundColor)
            let messageContent = botHTMLContent.html
            let content = "\(contentPrefix)\(messageContent)\(kWebViewContentSuffix)"
            
            let _ = webView.loadHTMLString(content, baseURL: Bundle.main.bundleURL)
        } else {
            loadingWheel.startAnimating()
        }
    }

}
