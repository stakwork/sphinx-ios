// DashboardFeedsEmptyStateViewController.swift
//
// Created by CypherPoet.
// ✌️
//
    

import UIKit


class DashboardFeedsEmptyStateViewController: UIViewController {
    typealias ContentFilterOption = DashboardFeedsContainerViewController.ContentFilterOption
    
    @IBOutlet weak var emptyStateMessageLabel: UILabel!
    
    var contentFilterOption: ContentFilterOption!
}
    

// MARK: -  Static Members
extension DashboardFeedsEmptyStateViewController {
    
    static func instantiate(
        contentFilterOption: ContentFilterOption
    ) -> DashboardFeedsEmptyStateViewController {
        let viewController = StoryboardScene
            .Dashboard
            .dashboardFeedsEmptyStateViewController
            .instantiate()
        
        viewController.contentFilterOption = contentFilterOption

        return viewController
    }
}


// MARK: -  Lifecycle
extension DashboardFeedsEmptyStateViewController {

    override func viewDidLoad() {
        super.viewDidLoad()

        emptyStateMessageLabel.text = emptyStateMessageText
    }

    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        emptyStateMessageLabel.text = emptyStateMessageText
    }
}



// MARK: -  Computeds
extension DashboardFeedsEmptyStateViewController {

    private var emptyStateMessageText: String {
        switch contentFilterOption.id {
        case ContentFilterOption.allContent.id:
            return "feed.no-feed-found".localized
        case ContentFilterOption.listen.id:
            return "feed.no-listen-found".localized
        case ContentFilterOption.watch.id:
            return "feed.no-watch-found".localized
        case ContentFilterOption.read.id:
            return "feed.no-read-found".localized
        case ContentFilterOption.play.id:
            return "feed.no-play-found".localized
        default:
            return "feed.no-feed-found".localized
        }
    }
}
