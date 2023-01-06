//
//  NewsletterItemDetailViewController.swift
//  sphinx
//
//  Created by Tomas Timinskas on 28/10/2021.
//  Copyright © 2021 sphinx. All rights reserved.
//

import UIKit
import WebKit
import CoreData

class NewsletterItemDetailViewController: UIViewController {
    
    weak var boostDelegate: CustomBoostDelegate?

    @IBOutlet weak var webview: WKWebView!
    @IBOutlet weak var loadingWheelContainer: UIView!
    @IBOutlet weak var loadingWheel: UIActivityIndicatorView!
    @IBOutlet weak var customBoostView: CustomBoostView!
    
    let feedBoostHelper = FeedBoostHelper()
    
    var newsletterItem: NewsletterItem!
    var contentFeed: ContentFeed? = nil
    
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
        newsletterItem: NewsletterItem,
        boostDelegate: CustomBoostDelegate
    ) -> NewsletterItemDetailViewController {
        let viewController = StoryboardScene
            .NewsletterFeed
            .newsletterItemDetailViewController
            .instantiate()
        
        viewController.newsletterItem = newsletterItem
        viewController.boostDelegate = boostDelegate
        
        if let feedID = newsletterItem.newsletterFeed?.objectID {
            viewController.contentFeed = CoreDataManager.sharedManager.getObjectWith(objectId: feedID)
        }
        
        return viewController
    }
}

// MARK: -  Private Helpers
extension NewsletterItemDetailViewController {
    
    func loadItem() {
        setupFeedBoostHelper()
        setupCustomBoost()
        
        webview.navigationDelegate = self
        
        if let itemURL = newsletterItem.itemUrl {
            let request = URLRequest(url: itemURL)
            webview.load(request)
        }
    }
    
    func setupFeedBoostHelper() {
        if let contentFeed = contentFeed {
            feedBoostHelper.configure(with: contentFeed.objectID, and: contentFeed.chat)
        }
    }
    
    func setupCustomBoost() {
        customBoostView.delegate = self
        
        if contentFeed?.destinationsArray.count == 0 {
            customBoostView.alpha = 0.3
            customBoostView.isUserInteractionEnabled = false
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

extension NewsletterItemDetailViewController: CustomBoostViewDelegate {
    func didStartBoostAmountEdit() {
        
    }
    
    func didTouchBoostButton(withAmount amount: Int) {
        let itemID = newsletterItem.itemID
        
        if let boostMessage = feedBoostHelper.getBoostMessage(itemID: itemID, amount: amount) {
            
            let podcastAnimationVC = PodcastAnimationViewController.instantiate(amount: amount)
            WindowsManager.sharedInstance.showConveringWindowWith(rootVC: podcastAnimationVC)
            podcastAnimationVC.showBoostAnimation()
            
            feedBoostHelper.processPayment(itemID: itemID, amount: amount)
            
            feedBoostHelper.sendBoostMessage(
                message: boostMessage,
                itemObjectID: newsletterItem.objectID,
                amount: amount,
                completion: { (message, success) in
                    self.boostDelegate?.didSendBoostMessage(success: success, message: message)
                }
            )
        }
    }
}
