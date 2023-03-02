//
//  FeedItemDetailVM_Q12023.swift
//  sphinx
//
//  Created by James Carucci on 3/2/23.
//  Copyright © 2023 sphinx. All rights reserved.
//

import Foundation
import UIKit

class FeedItemDetailVM_Q12023 : NSObject{
    
    var delegate: PodcastEpisodesDSDelegate?
    weak var vc: FeedItemDetailVC_Q12023?
    weak var tableView:UITableView?
    var episode : PodcastEpisode
    var indexPath : IndexPath
    let actionsList : [FeedItemActionType] = [
        .download,
        .share,
        .copyLink,
        .markAsPlayed
    ]
    
    init(vc:FeedItemDetailVC_Q12023,
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
        tableView?.register(UINib(nibName: "FeedItemDetailHeaderCellQ123", bundle: nil), forCellReuseIdentifier: FeedItemDetailHeaderCellQ123.reuseID)
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

extension FeedItemDetailVM_Q12023 : UITableViewDelegate, UITableViewDataSource{
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 1 + actionsList.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if indexPath.row  == 0{
            let cell = tableView.dequeueReusableCell(
                withIdentifier: FeedItemDetailHeaderCellQ123.reuseID,
                for: indexPath
            ) as! FeedItemDetailHeaderCellQ123
            cell.configureView(episode: episode)
            return cell
        }
        else{
            let cell = tableView.dequeueReusableCell(
                withIdentifier: "FeedItemDetailActionCell",
                for: indexPath
            ) as! FeedItemDetailActionCell
            cell.configureView(type: actionsList[indexPath.row - 1])
            return cell
        }
        
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if(indexPath.row == 0){
            return
        }
        else{
            let action = actionsList[indexPath.row - 1]
            doAction(action: action)
        }
    }
    
    
}
