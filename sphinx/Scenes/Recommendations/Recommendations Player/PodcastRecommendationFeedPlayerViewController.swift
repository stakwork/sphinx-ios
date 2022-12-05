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
    @IBOutlet weak var podcastPlaybackSliderView: PodcastPlayerPlaybackSliderView!
    
    var podcastItem: RecommendationResult! {
        didSet {
            DispatchQueue.main.async { [weak self] in
                guard let self = self else { return }

                self.updatePodcastPlayer(withNewEpisode: self.podcastItem)
            }
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
        podcastItem: RecommendationResult
    ) -> PodcastRecommendationFeedPlayerViewController {
        let viewController = StoryboardScene
            .Recommendations
            .podcastRecommendationFeedPlayerViewController
            .instantiate()
        
        viewController.podcastItem = podcastItem
    
        return viewController
    }
}

// MARK: -  Private Helpers
extension PodcastRecommendationFeedPlayerViewController {
    
    private func updatePodcastPlayer(withNewEpisode item: RecommendationResult) {
        if let imageURLString = item.imageURLPath, let url = URL(string: imageURLString) {
            recommendationItemImageView.sd_setImage(
                with: url,
                placeholderImage: UIImage(named: item.placeholderImageName ?? "podcastPlaceholder"),
                options: [.highPriority],
                progress: nil
            )
        } else {
            recommendationItemImageView.image = UIImage(named: item.placeholderImageName ?? "podcastPlaceholder")
        }
    }
}
