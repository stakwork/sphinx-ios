// PodcastFeedsContentEmptyStateViewController.swift
//
// Created by CypherPoet.
// ✌️
//
    

import UIKit


class PodcastFeedsContentEmptyStateViewController: UIViewController {}
    

// MARK: -  Static Members
extension PodcastFeedsContentEmptyStateViewController {
    
    static func instantiate(
    ) -> PodcastFeedsContentEmptyStateViewController {
        let viewController = StoryboardScene
            .Dashboard
            .podcastFeedsContentEmptyStateViewController
            .instantiate()

        return viewController
    }
}


// MARK: -  Lifecycle
extension PodcastFeedsContentEmptyStateViewController {

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }

}
