//
//  PodcastDetailView.swift
//  sphinx
//
//  Created by James Carucci on 3/2/23.
//  Copyright © 2023 sphinx. All rights reserved.
//

import Foundation
import UIKit

class FeedItemDetailVC : UIViewController{
    
    @IBOutlet weak var closeButton: UIButton!
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var detailView : UIView!
    
    weak var episode : PodcastEpisode?
    weak var video: Video?
    weak var delegateReference : PodcastEpisodesDSDelegate?
    var indexPath : IndexPath?
    
    
    lazy var vm : FeedItemDetailVM = {
        if let episode = episode{
            return FeedItemDetailVM(
                vc: self,
                tableView: self.tableView,
                episode:self.episode!,
                delegate: delegateReference!,
                indexPath:indexPath!
            )
        }
        else{
            return FeedItemDetailVM(
                vc: self,
                tableView: self.tableView,
                video:self.video!,
                delegate: delegateReference!,
                indexPath:indexPath!
            )
        }
        
    }()
    
    static func instantiate(
        episode:PodcastEpisode,
        delegate: PodcastEpisodesDSDelegate,
        indexPath: IndexPath
    ) -> FeedItemDetailVC {
        let viewController = StoryboardScene.Dashboard.feedItemDetailVC.instantiate()
        viewController.episode = episode
        viewController.delegateReference = delegate
        viewController.indexPath = indexPath
        return viewController
    }
    
    static func instantiate(
        video:Video,
        delegate: PodcastEpisodesDSDelegate,
        indexPath: IndexPath
    ) -> FeedItemDetailVC {
        let viewController = StoryboardScene.Dashboard.feedItemDetailVC.instantiate()
        viewController.video = video
        viewController.delegateReference = delegate
        viewController.indexPath = indexPath
        return viewController
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        addBlur()
        
        if let _ = self.episode{
            vm.setupTableView()
        }
        else if let _ = self.video{
            vm.setupTableView()
        }
    }
    
    @IBAction func closeTapped(_ sender: Any) {
        self.vm.delegate?.didDismiss()
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
