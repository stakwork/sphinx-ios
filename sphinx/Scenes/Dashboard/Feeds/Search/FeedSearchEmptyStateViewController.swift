// FeedSearchEmptyStateViewController.swift
//
// Created by CypherPoet.
// ✌️
//
    

import UIKit


class FeedSearchEmptyStateViewController: UIViewController {}
    

// MARK: -  Static Members
extension FeedSearchEmptyStateViewController {
    
    static func instantiate(
    ) -> FeedSearchEmptyStateViewController {
        let viewController = StoryboardScene
            .Dashboard
            .FeedSearchEmptyStateViewController
            .instantiate()

        return viewController
    }
}


// MARK: -  Lifecycle
extension FeedSearchEmptyStateViewController {

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }

}
