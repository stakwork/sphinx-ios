// PodcastFeedSearchEmptyStateViewController.swift
//
// Created by CypherPoet.
// ✌️
//
    

import UIKit


class PodcastFeedSearchEmptyStateViewController: UIViewController {}
    

// MARK: -  Static Members
extension PodcastFeedSearchEmptyStateViewController {
    
    static func instantiate(
    ) -> PodcastFeedSearchEmptyStateViewController {
        let viewController = StoryboardScene
            .Dashboard
            .podcastFeedSearchEmptyStateViewController
            .instantiate()

        return viewController
    }
}


// MARK: -  Lifecycle
extension PodcastFeedSearchEmptyStateViewController {

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }

}
