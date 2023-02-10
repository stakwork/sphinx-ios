//
//  BadgeMemberKnownBadgesVM.swift
//  sphinx
//
//  Created by James Carucci on 2/2/23.
//  Copyright © 2023 sphinx. All rights reserved.
//

import Foundation
import UIKit
import ObjectMapper

class BadgeMemberKnownBadgesVM : NSObject {
    
    var tableView : UITableView
    var vc : BadgeMemberKnownBadgesVC
    var knownBadges : [Badge] = []
    var chatID : Int? = nil
    
    init(vc: BadgeMemberKnownBadgesVC, tableView: UITableView,chatID:Int?) {
        self.vc = vc
        self.tableView = tableView
        self.chatID = chatID
    }
    
    func configureTable(){
        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(UINib(nibName: "KnownBadgeCell", bundle: nil), forCellReuseIdentifier: KnownBadgeCell.reuseID)
        
        fetchKnownBadges()
        
        tableView.reloadData()
    }
    
    func fetchKnownBadges(){
        /*
        let badge = Badge()
        badge.name = "my badge"
        badge.memo = "dexription of my badge"
        badge.icon_url = "https://i.ibb.co/Ch8mwg0/badge-Example.png"
        let badge2 = Badge()
        badge2.name = "my badge"
        badge2.memo = "dexription of my badge"
        badge2.icon_url = "https://i.ibb.co/Ch8mwg0/badge-Example.png"
        knownBadges.append(badge)
        knownBadges.append(badge2)
        */
        
        if let valid_id = chatID{
            vc.addLoadingView()
            API.sharedInstance.getTribeAdminBadges(
                chatID: valid_id,
                callback: { results in
                   print(results)
                    if var mappedResults = Mapper<Badge>().mapArray(JSONObject: Array(results)){
                        mappedResults.map({$0.chat_id = valid_id})
                        self.knownBadges = mappedResults
                        self.vc.removeLoadingView()
                        self.tableView.reloadData()
                    }
                },
                errorCallback: {
                    self.vc.removeLoadingView()
                })
        }
    }
    
}


extension BadgeMemberKnownBadgesVM : UITableViewDelegate, UITableViewDataSource{
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return knownBadges.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(
            withIdentifier: KnownBadgeCell.reuseID,
            for: indexPath
        ) as! KnownBadgeCell
        
        cell.configureCell(badge: knownBadges[indexPath.row])
        
        return cell
    }
    
    
}
