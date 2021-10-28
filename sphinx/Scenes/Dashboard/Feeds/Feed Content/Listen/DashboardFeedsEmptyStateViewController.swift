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
            return "No Feed Results Found."
        case ContentFilterOption.listen.id:
            return "No \"Listen\" Results Found."
        case ContentFilterOption.watch.id:
            return "No \"Watch\" Results Found."
        case ContentFilterOption.read.id:
            return "No \"Read\" Results Found."
        case ContentFilterOption.play.id:
            return "No \"Play\" Results Found."
        default:
            return "No Feed Results Found."
        }
    }
}
