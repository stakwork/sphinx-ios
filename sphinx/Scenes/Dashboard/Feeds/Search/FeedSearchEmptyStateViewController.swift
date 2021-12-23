// FeedSearchEmptyStateViewController.swift
//
// Created by CypherPoet.
// ✌️
//
    

import UIKit


class FeedSearchEmptyStateViewController: UIViewController {
    
    @IBOutlet weak var searchPlaceholderImage: UIImageView!
    @IBOutlet weak var searchPlaceholder1: UILabel!
    @IBOutlet weak var searchPlaceholder2: UILabel!
    @IBOutlet weak var searchPlaceholder3: UILabel!
    
    var feedType: FeedType? = nil
}
    

// MARK: -  Static Members
extension FeedSearchEmptyStateViewController {
    
    static func instantiate() -> FeedSearchEmptyStateViewController {
        let viewController = StoryboardScene
            .Dashboard
            .FeedSearchEmptyStateViewController
            .instantiate()

        return viewController
    }
}


// MARK: -  Lifecycle
extension FeedSearchEmptyStateViewController {
    
    override func didMove(toParent parent: UIViewController?) {
        super.didMove(toParent: parent)
        
        configureStartingEmptyStateView()
    }
    
    func configureStartingEmptyStateView() {
        searchPlaceholder1.text = "feed.search-over".localized
        
        switch(feedType) {
        case .Podcast:
            searchPlaceholderImage.isHidden = false
            searchPlaceholderImage.image = UIImage(named: "podcastIndexLogo")
            
            searchPlaceholder2.text = "feed.search-podcast-quantity".localized
            searchPlaceholder3.text = "feed.search-podcast-source".localized
            break
        case .Video:
            searchPlaceholderImage.isHidden = false
            searchPlaceholderImage.image = UIImage(named: "videoPlaceholder")
            
            searchPlaceholder2.text = "feed.search-video-quantity".localized
            searchPlaceholder3.text = "feed.search-video-source".localized
            break
        default:
            searchPlaceholderImage.isHidden = true
            
            searchPlaceholder2.text = "feed.search-other-source".localized
            searchPlaceholder3.text = ""
            break
        }
    }

}
