//
//  RecommendationFeedPlayerContainerViewController.swift
//  sphinx
//
//  Created by Tomas Timinskas on 02/12/2022.
//  Copyright © 2022 sphinx. All rights reserved.
//

import UIKit

class RecommendationFeedPlayerContainerViewController: UIViewController {
    
    @IBOutlet weak var playerContainerView: UIView!
    @IBOutlet weak var recommendationDetailsView: RecommendationDetailsView!
    @IBOutlet weak var collectionViewContainer: UIView!
    
    var recommendations: [RecommendationResult]!
    var recommendation: RecommendationResult!

    override func viewDidLoad() {
        super.viewDidLoad()
    }
}

// MARK: -  Static Methods
extension RecommendationFeedPlayerContainerViewController {
    
    static func instantiate(
        recommendations: [RecommendationResult],
        recommendation: RecommendationResult
    ) -> RecommendationFeedPlayerContainerViewController {
        let viewController = StoryboardScene
            .Recommendations
            .recommendationFeedPlayerContainerViewController
            .instantiate()
        
        viewController.recommendations = recommendations
        viewController.recommendation = recommendation
    
        return viewController
    }
}

