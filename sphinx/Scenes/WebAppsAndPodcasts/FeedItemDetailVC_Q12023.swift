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
    
    @IBOutlet weak var closeButton: UIButton!
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var detailView : UIView!
    
    weak var episode : PodcastEpisode?
    weak var delegateReference : PodcastEpisodesDSDelegate?
    var indexPath : IndexPath?
    
    
    lazy var vm : FeedItemDetailVM_Q12023 = {
        return FeedItemDetailVM_Q12023(
            vc: self,
            tableView: self.tableView,
            episode:self.episode!,
            delegate: delegateReference!,
            indexPath:indexPath!
        )
    }()
    
    static func instantiate(
        episode:PodcastEpisode,
        delegate: PodcastEpisodesDSDelegate,
        indexPath: IndexPath
    ) -> FeedItemDetailVC_Q12023 {
        let viewController = StoryboardScene.Dashboard.feedItemDetailVC_Q12023.instantiate()
        viewController.episode = episode
        viewController.delegateReference = delegate
        viewController.indexPath = indexPath
        return viewController
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        addBlur()
        
        if let _ = self.episode{
            vm.setupTableView()
            tableView.reloadData()
        }
    }
    
    @IBAction func closeTapped(_ sender: Any) {
        self.dismiss(animated: true)
    }
    
    func addBlur(){
        let blurEffect = UIBlurEffect(style: UIBlurEffect.Style.prominent)
        let effectView = UIVisualEffectView(effect: blurEffect)
        effectView.frame = self.detailView.bounds
        effectView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        self.detailView.addSubview(effectView)
        self.detailView.sendSubviewToBack(effectView)
    }
}
