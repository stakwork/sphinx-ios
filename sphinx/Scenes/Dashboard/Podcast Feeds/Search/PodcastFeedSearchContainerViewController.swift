// PodcastFeedSearchContainerViewController.swift
//
// Created by CypherPoet.
// ✌️
//
    

import UIKit


public protocol PodcastFeedSearchResultsViewControllerDelegate: AnyObject {
    
}


class PodcastFeedSearchContainerViewController: UIViewController {
 
    weak var resultsDelegate: PodcastFeedSearchResultsViewControllerDelegate?
}





// MARK: -  Static Properties
extension PodcastFeedSearchContainerViewController {
    
    static func instantiate(
        resultsDelegate: PodcastFeedSearchResultsViewControllerDelegate
    ) -> PodcastFeedSearchContainerViewController {
        let viewController = StoryboardScene
            .Dashboard
            .podcastFeedSearchContainerViewController
            .instantiate()
        
        viewController.resultsDelegate = resultsDelegate
        
        return viewController
    }

}


// MARK: -  Lifecycle
extension PodcastFeedSearchContainerViewController {
    override func viewDidLoad() {
        super.viewDidLoad()
    }
}
