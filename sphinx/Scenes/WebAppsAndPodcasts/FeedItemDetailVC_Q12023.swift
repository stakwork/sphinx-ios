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
        //viewController.rootViewController = rootViewController
        viewController.episode = episode
        viewController.delegateReference = delegate
        viewController.indexPath = indexPath
        return viewController
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.backgroundColor = .clear
        tableView.backgroundColor = .clear
        addBlur()
        if let _ = self.episode{
            vm.setupTableView()
            tableView.reloadData()
        }
        
        let closeString = "CLOSE"
        let closeButtonAttributedText = NSMutableAttributedString(string: closeString)
        closeButtonAttributedText.addAttribute(.foregroundColor, value: UIColor.Sphinx.BodyInverted, range: NSRange(location: 0, length: closeString.count))
        
        closeButtonAttributedText.addAttribute(.font,value: UIFont(name: "Montserrat", size: 12.0), range: NSRange(location:0, length: closeString.count))
        closeButton.setAttributedTitle(closeButtonAttributedText, for: [.normal,.highlighted])
        
    }
    @IBAction func closeTapped(_ sender: Any) {
        self.dismiss(animated: true)
    }
    
    func addBlur(){
        let blurEffect = UIBlurEffect(style: UIBlurEffect.Style.prominent)
        let effectView = UIVisualEffectView(effect: blurEffect)
        effectView.frame = self.view.bounds
        effectView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        self.view.addSubview(effectView)
        self.view.sendSubviewToBack(effectView)
    }
    
    
}
