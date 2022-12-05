//
//  PodcastRecommendationFeedPlayerViewController.swift
//  sphinx
//
//  Created by Tomas Timinskas on 02/12/2022.
//  Copyright © 2022 sphinx. All rights reserved.
//

import UIKit

class PodcastRecommendationFeedPlayerViewController: UIViewController {

    @IBOutlet weak var recommendationItemImageView: UIImageView!
    
    var podcastItem: RecommendationResult! {
        didSet {
//            DispatchQueue.main.async { [weak self] in
//                guard let self = self else { return }
//
//                self.updateVideoPlayer(withNewEpisode: self.videoItem)
//            }
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }
}

// MARK: -  Static Methods
extension PodcastRecommendationFeedPlayerViewController {
    
    static func instantiate(
        podcastItem: RecommendationResult,
        onDismiss: (() -> Void)?
    ) -> PodcastRecommendationFeedPlayerViewController {
        let viewController = StoryboardScene
            .Recommendations
            .podcastRecommendationFeedPlayerViewController
            .instantiate()
        
        viewController.podcastItem = podcastItem
    
        return viewController
    }
}
