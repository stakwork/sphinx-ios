// PodcastFeedsContentEmptyStateViewController.swift
//
// Created by CypherPoet.
// ✌️
//
    

import UIKit


class PodcastFeedsContentEmptyStateViewController: UIViewController {
    @IBOutlet weak var emptyStateMessageLabel: UILabel!
}
    

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

        emptyStateMessageLabel.text = "dashboard.feeds.content.empty-state-message".localized
    }

}
