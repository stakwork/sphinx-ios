//
//  NewsletterFeedContainerViewController.swift
//  sphinx
//
//  Created by Tomas Timinskas on 28/10/2021.
//  Copyright © 2021 sphinx. All rights reserved.
//

import UIKit
import CoreData

protocol NewsletterFeedContainerViewControllerDelegate: AnyObject {

    func viewController(
        _ viewController: UIViewController,
        didSelectNewsletterItemWithID newsletterItemId: NSManagedObjectID
    )
}

class NewsletterFeedContainerViewController: UIViewController {

    @IBOutlet weak var feedImageView: UIImageView!
    @IBOutlet weak var feedTitleLabel: UILabel!
    @IBOutlet weak var feedDescriptionLabel: UILabel!
    
    @IBOutlet weak var feedItemsView: UIView!
    
    var newsletterFeed: NewsletterFeed!
    
    var newsletterItems: [NewsletterItem] {
        get {
            return newsletterFeed.itemsArray
        }
    }
    
    weak var delegate: NewsletterFeedContainerViewControllerDelegate?
    
    internal lazy var collectionViewController: NewsletterFeedItemsCollectionViewController = {
        NewsletterFeedItemsCollectionViewController.instantiate(
            newsletterItems: newsletterFeed.itemsArray,
            onNewsletterItemCellSelected: handleNewsletterItemCellSelection(_:)
        )
    }()
}

// MARK: -  Lifecycle
extension NewsletterFeedContainerViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupViews()
        loadFeed()
        configureCollectionView()
        
        updateItems()
    }
}

// MARK: -  Private Helpers
extension NewsletterFeedContainerViewController {
    
    func setupViews() {
        feedImageView.layer.cornerRadius = 8
        feedImageView.clipsToBounds = true
    }
    
    func loadFeed() {
        feedImageView.sd_cancelCurrentImageLoad()
        
        if let imageUrl = newsletterFeed.imageURL {
            feedImageView.sd_setImage(
                with: imageUrl,
                placeholderImage: UIImage(named: "newsletterPlaceholder"),
                options: [.highPriority],
                progress: nil
            )
        } else if let imageUrlString = newsletterFeed.chat?.photoUrl, let imageUrl = URL(string: imageUrlString) {
            feedImageView.sd_setImage(
                with: imageUrl,
                placeholderImage: UIImage(named: "newsletterPlaceholder"),
                options: [.highPriority],
                progress: nil
            )
        } else {
            feedImageView.image = UIImage(named: "profile_avatar")
        }
        
        feedTitleLabel.text = newsletterFeed.title
        feedDescriptionLabel.text = newsletterFeed.feedDescription
    }
    
    private func configureCollectionView() {
        addChildVC(
            child: collectionViewController,
            container: feedItemsView
        )
    }
}

// MARK: -  Static Methods
extension NewsletterFeedContainerViewController {
    
    static func instantiate(
        newsletterFeed: NewsletterFeed,
        delegate: NewsletterFeedContainerViewControllerDelegate
    ) -> NewsletterFeedContainerViewController {
        let viewController = StoryboardScene
            .NewsletterFeed
            .newsletterFeedContainerViewController
            .instantiate()
        
        viewController.newsletterFeed = newsletterFeed
        viewController.delegate = delegate
        
        return viewController
    }
}

// MARK: -  Action Handling
extension NewsletterFeedContainerViewController {
    
    private func handleNewsletterItemCellSelection(
        _ managedObjectID: NSManagedObjectID
    ) {
        let context = CoreDataManager.sharedManager.persistentContainer.viewContext
        
        guard
            let selectedItem = context.object(with: managedObjectID) as? ContentFeedItem,
            selectedItem.contentFeed?.isNewsletter == true
        else {
            return
        }

        self.dismiss(animated: false, completion: {
            self.delegate?.viewController(self, didSelectNewsletterItemWithID: selectedItem.objectID)
        })
    }
    
    
    private func updateItems() {
        if let objectId = self.newsletterFeed?.objectID,
           let feedUrl = self.newsletterFeed?.feedURL?.absoluteString {
            
            ContentFeed.fetchFeedItemsInBackground(feedUrl: feedUrl, contentFeedObjectID: objectId, completion: {})
        }
    }
}
