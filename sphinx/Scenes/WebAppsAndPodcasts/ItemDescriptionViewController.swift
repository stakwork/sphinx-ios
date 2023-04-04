//
//  ItemDescriptionViewController.swift
//  sphinx
//
//  Created by James Carucci on 4/4/23.
//  Copyright © 2023 sphinx. All rights reserved.
//

import Foundation
import UIKit

class ItemDescriptionViewController : UIViewController{
    
    override func viewDidLoad() {
        self.view.backgroundColor = .purple
    }
    
    static func instantiate(
        //podcast: PodcastFeed,
        //episode: PodcastEpisode
    ) -> ItemDescriptionViewController {
        let viewController = StoryboardScene.WebApps.itemDescriptionViewController.instantiate()
        
       // viewController.podcast = podcast
       // viewController.delegate = delegate
       // viewController.boostDelegate = boostDelegate
       // viewController.fromDashboard = fromDashboard
    
        return viewController
    }
}
