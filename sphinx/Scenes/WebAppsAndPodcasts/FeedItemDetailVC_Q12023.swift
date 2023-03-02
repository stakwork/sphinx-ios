//
//  PodcastDetailViewQ12023.swift
//  sphinx
//
//  Created by James Carucci on 3/2/23.
//  Copyright © 2023 sphinx. All rights reserved.
//

import Foundation
import UIKit

class FeedItemDetailVC_Q12023 : UIViewController{
    
    @IBOutlet weak var tableView: UITableView!
    weak var episode : PodcastEpisode?
    weak var delegateReference : PodcastEpisodesDSDelegate?
    
    lazy var vm : FeedItemDetailVM_Q12023 = {
        return FeedItemDetailVM_Q12023(vc: self, tableView: self.tableView,episode:self.episode!, delegate: delegateReference!)
    }()
    
    static func instantiate(
        episode:PodcastEpisode,
        delegate: PodcastEpisodesDSDelegate
    ) -> FeedItemDetailVC_Q12023 {
        let viewController = StoryboardScene.Dashboard.feedItemDetailVC_Q12023.instantiate()
        //viewController.rootViewController = rootViewController
        viewController.episode = episode
        viewController.delegateReference = delegate
        return viewController
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        if let _ = self.episode{
            vm.setupTableView()
            tableView.reloadData()
        }
    }
}
