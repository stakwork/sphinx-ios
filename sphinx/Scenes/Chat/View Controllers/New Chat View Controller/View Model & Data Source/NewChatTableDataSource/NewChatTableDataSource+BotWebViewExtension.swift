//
//  NewChatTableDataSource+BotWebViewExtension.swift
//  sphinx
//
//  Created by Tomas Timinskas on 21/06/2023.
//  Copyright © 2023 sphinx. All rights reserved.
//

import WebKit

extension NewChatTableDataSource : WKNavigationDelegate {
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        
        let kDocumentReadyJSCommand = "document.readyState"
        let kGetContainerJSCommand = "document.getElementById(\"bot-response-container\").clientHeight"
        
        webView.evaluateJavaScript(
            kDocumentReadyJSCommand,
            completionHandler: { (complete, error) in
                if complete == nil {
                    return
                }
            
                webView.evaluateJavaScript(
                    kGetContainerJSCommand,
                    completionHandler: { (height, error) in
                        if let height = height as? CGFloat {
                            self.webViewLoadingCompletion?(
                                height + (MessageTableCellState.kLabelMargin * 2) + 10
                            )
                        } else {
                            self.webViewLoadingCompletion?(nil)
                        }
                    }
                )
            }
        )
    }
    
    func loadWebViewContent(
        _ content: String,
        completion: @escaping (CGFloat?) -> ()
    ) {
        self.webViewLoadingCompletion = completion
        
        let kWebViewContentPrefix = "<head><meta name=\"viewport\" content=\"width=device-width, height=device-height, shrink-to-fit=YES\"></head><body style=\"font-family: 'Roboto', sans-serif; color: #000000; margin:0px !important; padding:0px!important; background: #ffffff;\"><div id=\"bot-response-container\" style=\"background: #ffffff;\">"
        let kWebViewContentSuffix = "</div></body>"

        let content = "\(kWebViewContentPrefix)\(content)\(kWebViewContentSuffix)"
        
        DispatchQueue.main.async {
            self.webView.navigationDelegate = self
            
            let _ = self.webView.loadHTMLString(
                content,
                baseURL: Bundle.main.bundleURL
            )
        }
    }
}
