//
//  ProfileManageStorageSourceDetailsVM.swift
//  sphinx
//
//  Created by James Carucci on 5/23/23.
//  Copyright © 2023 sphinx. All rights reserved.
//

import Foundation
import UIKit

class ProfileManageStorageSourceDetailsVM : NSObject{
    
    var vc : ProfileManageStorageSourceDetailsVC
    var tableView: UITableView
    var source:StorageManagerMediaSource
    
    var chatDict : [Chat : [StorageManagerItem]]? = nil
    var chatsArray = [Chat](){
        didSet{
            vc.totalSize = StorageManager.sharedManager.getItemGroupTotalSize(items: getSourceItems())
            vc.setupView()
        }
    }
    
    var podsDict : [PodcastFeed:[StorageManagerItem]]? = nil
    var podsArray = [PodcastFeed](){
        didSet{
            vc.totalSize = StorageManager.sharedManager.getItemGroupTotalSize(items: getSourceItems())
            vc.setupView()
        }
    }
    
    func getChatsArray()->[Chat]{
        if let chatDict = chatDict{
            return chatDict.keys.sorted(by: {$0.getName().lowercased() ?? "" < $1.getName().lowercased() ?? ""})
        }
        return []
    }
    func getPodsArray()->[PodcastFeed]{
        if let podsDict = podsDict{
            return podsDict.keys.sorted(by: {$0.title ?? "" < $1.title ?? ""})
        }
        return []
    }
    
    init(vc:ProfileManageStorageSourceDetailsVC,tableView:UITableView,source:StorageManagerMediaSource){
        self.vc = vc
        self.tableView = tableView
        self.source = source
    }
    
    func finishSetup(){
        getDataSource()
        tableView.delegate = self
        tableView.dataSource = self
        
        tableView.register(UINib(nibName: "MediaStorageSourceTableViewCell", bundle: nil), forCellReuseIdentifier: MediaStorageSourceTableViewCell.reuseID)
    }
    
    func getDataSource(){
        switch(source){
        case .podcasts:
            podsDict = StorageManager.sharedManager.getItemDetailsByPodcastFeed()
            podsArray = getPodsArray()
            break
        case .chats:
            chatDict = StorageManager.sharedManager.getItemDetailsByChat()
            chatsArray = getChatsArray()
            break
        }
    }
    
    func getSourceItems()->[StorageManagerItem]{
        switch(source){
        case .podcasts:
            if let podsDict = podsDict,
               let items = podsDict.values.flatMap({ $0 }) as? [StorageManagerItem]{
                return items
            }
            
            break
        case .chats:
            if let chatDict = chatDict,
               let items = chatDict.values.flatMap({ $0 }) as? [StorageManagerItem]{
                return items
            }
            break
        }
        return []
    }
    
}

extension ProfileManageStorageSourceDetailsVM : UITableViewDelegate,UITableViewDataSource{
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        if source == .chats,
           let chatData = chatDict{
            return chatsArray.count
        }
        else if source == .podcasts,
            let podsData = podsDict{
            return podsArray.count
        }
        
        return 0
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(
            withIdentifier: MediaStorageSourceTableViewCell.reuseID,
            for: indexPath
        ) as! MediaStorageSourceTableViewCell
        if source == .chats{
            let chosenChat = chatsArray[indexPath.row]
            let items = chatDict?[chosenChat] ?? []
            cell.configure(forChat: chosenChat, items: items)
        }
        else if source == .podcasts{
            let chosenFeed = podsArray[indexPath.row]
            let items = podsDict?[chosenFeed] ?? []
            cell.configure(podcastFeed: chosenFeed, items: items)
        }
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        switch(source){
        case .chats:
            let chat = chatsArray[indexPath.row]
            if let chatDict = chatDict,
               let items = chatDict[chat]{
                vc.showItemSpecificDetails(podcastFeed: nil, chat: chat, sourceType: .chats,items: items)
            }
            break
        case .podcasts:
            let pod = podsArray[indexPath.row]
            if let podsDict = podsDict,
               let items = podsDict[pod]{
                vc.showItemSpecificDetails(podcastFeed: pod, chat: nil, sourceType: .podcasts, items: items)
            }
            break
        }
        tableView.deselectRow(at: indexPath, animated: true)
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        // Specify the desired height for your cells
        return 64.0 // Adjust this value according to your requirements
    }
}
