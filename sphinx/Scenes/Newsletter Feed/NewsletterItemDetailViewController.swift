//
//  NewsletterItemDetailViewController.swift
//  sphinx
//
//  Created by Tomas Timinskas on 28/10/2021.
//  Copyright © 2021 sphinx. All rights reserved.
//

import UIKit
import WebKit

class NewsletterItemDetailViewController: UIViewController {

    @IBOutlet weak var webview: WKWebView!
    @IBOutlet weak var loadingWheelContainer: UIView!
    @IBOutlet weak var loadingWheel: UIActivityIndicatorView!
    
    var newsletterItem: NewsletterItem!
    
    var loading = false {
        didSet {
            if (loading) {
                loadingWheel.startAnimating()
            } else {
                loadingWheel.stopAnimating()
            }
            loadingWheelContainer.isHidden = !loading
        }
    }
    
    @IBAction func closeButtonTouched() {
        self.dismiss(animated: true, completion: nil)
    }
    
}

// MARK: -  Lifecycle
extension NewsletterItemDetailViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        toggleLoadingWheel(true)
        
        newsletterItem.saveAsCurrentArticle()
        newsletterItem.newsletterFeed?.chat?.updateWebAppLastDate()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        loadItem()
    }
}

// MARK: -  Static Methods
extension NewsletterItemDetailViewController {
    
    static func instantiate(
        newsletterItem: NewsletterItem
    ) -> NewsletterItemDetailViewController {
        let viewController = StoryboardScene
            .NewsletterFeed
            .newsletterItemDetailViewController
            .instantiate()
        
        viewController.newsletterItem = newsletterItem
        
        return viewController
    }
}

// MARK: -  Private Helpers
extension NewsletterItemDetailViewController {
    
    func loadItem() {
        webview.navigationDelegate = self
        
        if let itemURL = newsletterItem.itemUrl {
            let request = URLRequest(url: itemURL)
            webview.load(request)
        }
    }
    
    func toggleLoadingWheel(_ show: Bool) {
        loading = false
    }
}

extension NewsletterItemDetailViewController : WKNavigationDelegate {
    func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
        self.toggleLoadingWheel(true)
    }
    
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        self.toggleLoadingWheel(false)
    }
}
