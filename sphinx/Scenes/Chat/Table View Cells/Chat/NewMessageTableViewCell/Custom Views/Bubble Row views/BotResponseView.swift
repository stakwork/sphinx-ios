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
    var contentString : String? = nil
    var messageId: Int? = nil
    
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
        contentString = botHTMLContent.html
        loadingWheel.isHidden = !loading
        webView.isHidden = loading
        
        if !loading {
            loadingWheel.stopAnimating()
            
            let backgroundColor = UIColor(cgColor: UIColor.Sphinx.ReceivedMsgBG.resolvedCGColor(with: self)).toHexColorString()
            let textColor = UIColor(cgColor: UIColor.Sphinx.Text.resolvedCGColor(with: self)).toHexColorString()
            
            let contentPrefix = String(format: kWebViewContentPrefix, textColor, backgroundColor, backgroundColor)
            let messageContent = botHTMLContent.html
            let content = "\(contentPrefix)\(messageContent)\(kWebViewContentSuffix)"
            
            let _ = webView.loadHTMLString(content, baseURL: Bundle.main.bundleURL)
            self.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(handleWebViewTap)))
        } else {
            loadingWheel.startAnimating()
        }
    }
    
    @objc func handleWebViewTap(){
        let srcPattern = #"src="([^"]+)""#
        guard let mid = self.messageId
        else{
            return
        }
        // Create a regular expression object
        if let regex = try? NSRegularExpression(pattern: srcPattern, options: .caseInsensitive),
           let contentString = contentString {
            // Find matches in the contentString
            let matches = regex.matches(in: contentString, options: [], range: NSRange(location: 0, length: contentString.utf16.count))

            // Loop through the matches and extract the src attribute
            for match in matches {
                if let srcRange = Range(match.range(at: 1), in: contentString) {
                    let srcAttribute = contentString[srcRange]
                    print("Found src attribute: \(srcAttribute)")
                    if let url = URL(string: String(srcAttribute)){
                       NotificationCenter.default.post(name: .webViewImageClicked, object: nil, userInfo: ["imageURL": url,"messageId":mid])
                    }
                }
            }
        }
    }

}
