//
//  FeedItemDetailVM.swift
//  sphinx
//
//  Created by James Carucci on 3/2/23.
//  Copyright © 2023 sphinx. All rights reserved.
//

import Foundation
import UIKit

class FeedItemDetailVM : NSObject{
    
    var delegate: PodcastEpisodesDSDelegate?
    weak var vc: FeedItemDetailVC?
    weak var tableView:UITableView?
    var episode : PodcastEpisode
    var indexPath : IndexPath
    
    func getActionsList() -> [FeedItemActionType]{
        if(episode.type == "youtube"){
            return [
                .share,
                .copyLink,
                .markAsPlayed
            ]
        }
        else{
            return [
                .download,
                .share,
                .copyLink,
                .markAsPlayed
            ]
        }
    }
    
    init(vc:FeedItemDetailVC,
         tableView:UITableView,
         episode:PodcastEpisode,
         delegate:PodcastEpisodesDSDelegate,
         indexPath:IndexPath){
        self.vc = vc
        self.tableView = tableView
        self.episode = episode
        self.delegate = delegate
        self.indexPath = indexPath
    }
    
    func setupTableView(){
        tableView?.register(UINib(nibName: "FeedItemDetailHeaderCell", bundle: nil), forCellReuseIdentifier: FeedItemDetailHeaderCell.reuseID)
        tableView?.register(UINib(nibName: "FeedItemDetailActionCell", bundle: nil), forCellReuseIdentifier: "FeedItemDetailActionCell")
        
        tableView?.delegate = self
        tableView?.dataSource = self
    }
    
    func doAction(action:FeedItemActionType){
        switch(action){
        case .download:
            vc?.dismiss(animated: true)
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1, execute: {
                self.delegate?.downloadTapped(self.indexPath, episode: self.episode)
            })
            break
        case .markAsPlayed:
            vc?.dismiss(animated: true)
            episode.wasPlayed = true
            NewMessageBubbleHelper().showGenericMessageView(text: "Marking episode as played!")
            if let delegate = delegate as? NewPodcastPlayerViewController{
                delegate.reload(indexPath.row)
            }
            else if let delegate = delegate as? RecommendationFeedItemsCollectionViewController{
                delegate.configureDataSource(for: delegate.collectionView)
            }
            break
        case .copyLink:
            if let link = episode.linkURLPath{
                ClipboardHelper.copyToClipboard(text: link)
            }
            else{
                NewMessageBubbleHelper().showGenericMessageView(text: "Error copying link.")
            }
            break
        case .share:
            vc?.dismiss(animated: true)
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1, execute: {
                self.delegate?.shareTapped(episode: self.episode)
            })
            break
        }
    }
    
}

extension FeedItemDetailVM : UITableViewDelegate, UITableViewDataSource{
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 1 + getActionsList().count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if indexPath.row  == 0{
            let cell = tableView.dequeueReusableCell(
                withIdentifier: FeedItemDetailHeaderCell.reuseID,
                for: indexPath
            ) as! FeedItemDetailHeaderCell
            cell.configureView(episode: episode)
            return cell
        }
        else{
            let cell = tableView.dequeueReusableCell(
                withIdentifier: "FeedItemDetailActionCell",
                for: indexPath
            ) as! FeedItemDetailActionCell
            cell.configureView(type: getActionsList()[indexPath.row - 1])
            cell.selectionStyle = .none
            return cell
        }
        
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if(indexPath.row == 0){
            return
        }
        else{
            let action = getActionsList()[indexPath.row - 1]
            doAction(action: action)
        }
    }
}
