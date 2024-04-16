//
//  WebAppViewController.swift
//  sphinx
//
//  Created by Tomas Timinskas on 19/08/2020.
//  Copyright © 2020 Sphinx. All rights reserved.
//

import UIKit
import WebKit

class WebAppViewController: KeyboardEventsViewController {
    
    @IBOutlet weak var authorizeModalContainer: UIView!
    @IBOutlet weak var authorizeModalView: AuthorizeAppView!
    @IBOutlet weak var authorizeModalViewHeight: NSLayoutConstraint!
    @IBOutlet weak var authorizeViewVerticalConstraint: NSLayoutConstraint!
    
    var webView: WKWebView!
    var gameURL: String! = nil
    var chat: Chat! = nil
    
    let webAppHelper = WebAppHelper()
    
    static func instantiate(
        chat: Chat,
        isAppURL: Bool = true
    ) -> WebAppViewController? {
        let viewController = StoryboardScene.WebApps.webAppViewController.instantiate()
        viewController.chat = chat
        
        guard let tribeInfo = chat.tribeInfo, let gameURL = isAppURL ? tribeInfo.appUrl : tribeInfo.secondBrainUrl, !gameURL.isEmpty else {
            return nil
        }

        viewController.gameURL = gameURL
        
        return viewController
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        
        authorizeModalView.layer.cornerRadius = 10
        authorizeModalView.clipsToBounds = true
        
        addWebView()
        loadPage()
    }

    @objc override func keyboardWillShow(_ notification: Notification) {
        if let keyboardHeight = (notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue.height, keyboardHeight > authorizeModalView.kAccessoryViewHeight {
            toggleModalPosition(keyboardShown: true)
        }
    }

    @objc override func keyboardWillHide(_ notification: Notification) {
        toggleModalPosition(keyboardShown: false)
    }
    
    func toggleModalPosition(keyboardShown: Bool) {
        authorizeViewVerticalConstraint.constant = keyboardShown ? -160 : 0
        authorizeModalView.superview?.layoutIfNeeded()
    }
    
    func addWebView() {
        let configuration = WKWebViewConfiguration()
        configuration.userContentController.add(webAppHelper, name: webAppHelper.messageHandler)
        let rect = CGRect(x: 0, y: 0, width: 700, height: 500)
        webView = WKWebView(frame: rect, configuration: configuration)
        webView.customUserAgent = "Sphinx"
        webView.navigationDelegate = self
        
        self.view.addSubview(webView)
        addWebViewConstraints()
        
        webAppHelper.setWebView(webView, authorizeHandler: configureAuthorizeView, authorizeBudgetHandler: configureBudgetView)
    }
    
    func configureAuthorizeView(_ dict: [String: AnyObject]) {
        let viewHeight = authorizeModalView.configureFor(url: gameURL, delegate: self, dict: dict, showBudgetField: false)
        authorizeModalViewHeight.constant = viewHeight
        authorizeModalView.layoutIfNeeded()
        view.bringSubviewToFront(authorizeModalContainer)
        toggleAuthorizationView(show: true)
    }
    
    func configureBudgetView(_ dict: [String: AnyObject]) {
        let viewHeight = authorizeModalView.configureFor(url: gameURL, delegate: self, dict: dict, showBudgetField: true)
        authorizeModalViewHeight.constant = viewHeight
        authorizeModalView.layoutIfNeeded()
        view.bringSubviewToFront(authorizeModalContainer)
        toggleAuthorizationView(show: true)
    }
    
    func addWebViewConstraints() {
        webView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint(item: self.view, attribute: NSLayoutConstraint.Attribute.bottom, relatedBy: NSLayoutConstraint.Relation.equal, toItem: webView, attribute: NSLayoutConstraint.Attribute.bottom, multiplier: 1.0, constant: 0.0).isActive = true
        NSLayoutConstraint(item: self.view, attribute: NSLayoutConstraint.Attribute.top, relatedBy: NSLayoutConstraint.Relation.equal, toItem: webView, attribute: NSLayoutConstraint.Attribute.top, multiplier: 1.0, constant: 0.0).isActive = true
        NSLayoutConstraint(item: self.view, attribute: NSLayoutConstraint.Attribute.leading, relatedBy: NSLayoutConstraint.Relation.equal, toItem: webView, attribute: NSLayoutConstraint.Attribute.leading, multiplier: 1.0, constant: 0.0).isActive = true
        NSLayoutConstraint(item: self.view, attribute: NSLayoutConstraint.Attribute.trailing, relatedBy: NSLayoutConstraint.Relation.equal, toItem: webView, attribute: NSLayoutConstraint.Attribute.trailing, multiplier: 1.0, constant: 0.0).isActive = true
    }
    
    func loadPage() {
        var url: String = gameURL
        
        if let tribeUUID = chat.tribeInfo?.uuid {
            url = url.withURLParam(key: "uuid", value: tribeUUID)
        }
        
        if let host = chat.host {
            url = url.withURLParam(key: "host", value: host)
        }
        
        if let url = URL(string: url) {
            let request = URLRequest(url: url)
            webView.load(request)
        }
    }
    
    func stopWebView() {
        webView.configuration.userContentController.removeAllUserScripts()
        webView.loadHTMLString("", baseURL: Bundle.main.bundleURL)
    }
}

extension WebAppViewController : WKNavigationDelegate {
    func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        if navigationAction.navigationType == .linkActivated  {
            if let url = navigationAction.request.url, url.absoluteString.contains("open=system") {
                UIApplication.shared.open(
                    url,
                    options: [:],
                    completionHandler: nil
                )
                decisionHandler(.cancel)
                return
            } else {
                decisionHandler(.allow)
                return
            }
        } else {
            decisionHandler(.allow)
            return
        }
    }
}

extension WebAppViewController : AuthorizeAppViewDelegate {
    func shouldClose() {
        toggleAuthorizationView(show: false)
    }
    
    func toggleAuthorizationView(show: Bool) {
        UIView.animate(withDuration: 0.3, animations: {
            self.authorizeModalContainer.alpha = show ? 1.0 : 0.0
        })
    }
    
    func shouldAuthorizeBudgetWith(amount: Int, dict: [String : AnyObject]) {
        webAppHelper.authorizeWebApp(amount: amount, dict: dict, completion: {
            self.chat.updateWebAppLastDate()
            self.shouldClose()
        })
    }
    
    func shouldAuthorizeWith(dict: [String : AnyObject]) {
        webAppHelper.authorizeNoBudget(dict: dict, completion: {
            self.chat.updateWebAppLastDate()
            self.shouldClose()
        })
    }
}
