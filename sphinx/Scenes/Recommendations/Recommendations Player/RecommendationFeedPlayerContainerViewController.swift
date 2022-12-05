//
//  RecommendationFeedPlayerContainerViewController.swift
//  sphinx
//
//  Created by Tomas Timinskas on 02/12/2022.
//  Copyright © 2022 sphinx. All rights reserved.
//

import UIKit

protocol CommonPlayerViewController: UIViewController {
    var recommendation: RecommendationResult! { get set }
}

class RecommendationFeedPlayerContainerViewController: UIViewController {
    
    @IBOutlet weak var playerContainerView: UIView!
    @IBOutlet weak var recommendationDetailsView: RecommendationDetailsView!
    @IBOutlet weak var collectionViewContainer: UIView!
    
    var recommendations: [RecommendationResult]!
    
    var recommendation: RecommendationResult! {
        didSet {
            DispatchQueue.main.async { [weak self] in
                guard
                    let self = self,
                    let recommendation = self.recommendation
                else { return }
                
                self.collectionViewController
                    .updateWithNew(recommendation: recommendation)
                
                self.recommendationDetailsView.configure(
                    withRecommendation: recommendation
                )
                
                self.youtubeVideoPlayerViewController.videoItem = recommendation
            }
        }
    }

    internal lazy var youtubeVideoPlayerViewController: YoutubeRecommendationFeedPlayerViewController = {
        YoutubeRecommendationFeedPlayerViewController.instantiate(videoItem: recommendation)
    }()
    
    internal lazy var collectionViewController: RecommendationFeedItemsCollectionViewController = {
        RecommendationFeedItemsCollectionViewController.instantiate(
            recommendation: recommendation,
            recommendations: recommendations,
            onRecommendationCellSelected: handleRecommendationCellSelection(_:)
        )
    }()
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

// MARK: -  Lifecycle
extension RecommendationFeedPlayerContainerViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        configurePlayerView()
        configureCollectionView()
    }
}

// MARK: -  Private Helpers
extension RecommendationFeedPlayerContainerViewController {
    
    private func configurePlayerView() {
        addChildVC(
            child: youtubeVideoPlayerViewController,
            container: playerContainerView
        )
    }

    private func configureCollectionView() {
        addChildVC(
            child: collectionViewController,
            container: collectionViewContainer
        )
    }
}

// MARK: -  Action Handling
extension RecommendationFeedPlayerContainerViewController {
    
    private func handleRecommendationCellSelection(
        _ recommendationId: String
    ) {
        guard
            let recommendation = recommendations.filter({ $0.id == recommendationId }).first
        else {
            preconditionFailure()
        }
        
        self.recommendation = recommendation
    }
}
