//
//  SubscriptionDetailsViewController.swift
//  sphinx
//
//  Created by Tomas Timinskas on 18/12/2019.
//  Copyright © 2019 Sphinx. All rights reserved.
//

import UIKit

class SubscriptionDetailsViewController: UIViewController {
    
    weak var delegate: QRCodeScannerDelegate?
    
    @IBOutlet weak var subscriptionImageView: UIImageView!
    @IBOutlet weak var subscriptionNameLabel: UILabel!
    @IBOutlet weak var subscriptionAmountLabel: UILabel!
    @IBOutlet weak var subscriptionIntervalLabel: UILabel!
    @IBOutlet weak var subscriptionEndRuleTitleLabel: UILabel!
    @IBOutlet weak var subscriptionEndRuleLabel: UILabel!
    @IBOutlet weak var subscribeButton: UIButton!
    @IBOutlet weak var loadingWheel: UIActivityIndicatorView!
    
    var loading = false {
        didSet {
            LoadingWheelHelper.toggleLoadingWheel(loading: loading, loadingWheel: loadingWheel, loadingWheelColor: UIColor.white, view: view)
        }
    }
    
    var subscription : SubscriptionManager.SubscriptionQR!
    
    let subscriptionManager = SubscriptionManager.sharedInstance
    
    static func instantiate(
        subscriptionQR: SubscriptionManager.SubscriptionQR,
        delegate: QRCodeScannerDelegate? = nil
    ) -> SubscriptionDetailsViewController {
        let viewController = StoryboardScene.Subscription.subscriptionDeatilsViewController.instantiate()
        viewController.subscription = subscriptionQR
        viewController.delegate = delegate
        return viewController
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setStatusBarColor()
        
        subscribeButton.setBackgroundColor(color: UIColor.Sphinx.PrimaryBlueBorder, forUIControlState: .highlighted)
        subscribeButton.setBackgroundColor(color: UIColor.Sphinx.PrimaryBlueBorder, forUIControlState: .selected)
        subscribeButton.layer.cornerRadius = subscribeButton.frame.size.height / 2
        subscribeButton.clipsToBounds = true
        
        completeSubscriptionDetails()
    }
    
    func completeSubscriptionDetails() {
        if let imageUrl = subscription.imgurl?.trim(), let nsUrl = URL(string: imageUrl), imageUrl != "" {
            subscriptionImageView.contentMode = .scaleAspectFill
            subscriptionImageView.layer.cornerRadius = 5
            MediaLoader.asyncLoadImage(imageView: subscriptionImageView, nsUrl: nsUrl, placeHolderImage: UIImage(named: "profile_avatar"))
        } else {
            subscriptionImageView.layer.cornerRadius = subscriptionImageView.frame.size.height / 2
            subscriptionImageView.image = UIImage(named: "profile_avatar")
        }
        
        subscriptionAmountLabel.text = "\(subscription.amount ?? 0)"
        subscriptionIntervalLabel.text = "sat / \(subscription.interval ?? "")"
        subscriptionNameLabel.text = "\(subscription.nickname ?? "name.unknown".localized)"
        
        subscriptionEndRuleLabel.text = ""
        
        if let endNumber = subscription.endNumber {
            subscriptionEndRuleTitleLabel.text = "total.payments".localized
            subscriptionEndRuleLabel.text = "\(endNumber)"
        } else if let endDate = subscription.endDate {
            subscriptionEndRuleTitleLabel.text = "pay.until".localized
            subscriptionEndRuleLabel.text = "\(endDate.getStringFromDate(format: "MMM dd, yyyy"))"
        }
    }
    
    func showErrorAlert(message: String) {
        loading = false
        AlertHelper.showAlert(title: "generic.error.title".localized, message: message)
    }
    
    func subscribe() {
        loading = true
        
        guard let pubkey = subscription.pubKey else {
            showErrorAlert(message: "generic.error.message".localized)
            return
        }
        
        guard let contact = UserContact.getContactWith(pubkey: pubkey) else {
            UserContactsHelper.createContact(nickname: subscription.nickname ?? "name.unknown".localized, pubKey: pubkey, photoUrl: subscription.imgurl, callback: { (success, _) in
                if success {
                    self.subscribe()
                } else {
                    self.showErrorAlert(message: "generic.error.message".localized)
                }
            })
            return
        }
        
        if let _ = contact.getCurrentSubscription() {
            self.showErrorAlert(message: "already.subscribed".localized)
            return
        }
        
        subscriptionManager.contact = contact
        createSubscription()
    }
    
    func createSubscription() {
        subscriptionManager.createOrEditSubscription(completion: { subscription, message in
            if let _ = subscription {
                DelayPerformedHelper.performAfterDelay(seconds: 1.0) {
                    self.dismissView()
                }
            } else if message != "" {
                self.showErrorAlert(message: message)
            }
        })
    }
    
    func dismissView() {
        delegate?.willDismissPresentedView?(paymentCreated: false)
        self.dismiss(animated: true)
    }
    
    @IBAction func subscribeButtonTouched() {
        subscribe()
    }
    
    @IBAction func closeButtonTouched() {
        delegate?.willDismissPresentedView?(paymentCreated: false)
        self.dismiss(animated: true, completion: nil)
    }
}
