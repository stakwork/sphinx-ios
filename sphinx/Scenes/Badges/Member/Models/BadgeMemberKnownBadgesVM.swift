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
    
    var knownBadges : [Badge] = []{
        didSet {
            vc.noBadgesLabel.isHidden = knownBadges.isEmpty == false
        }
    }
    var chatID : Int? = nil
    
    let kRowHeight:CGFloat = 117
    
    init(vc: BadgeMemberKnownBadgesVC, tableView: UITableView,chatID:Int?) {
        self.vc = vc
        self.tableView = tableView
        self.chatID = chatID
    }
    
    func setBadges(badges:[Badge]){
        self.knownBadges = badges
    }
    
    func configureTable(){
        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(UINib(nibName: "KnownBadgeCell", bundle: nil), forCellReuseIdentifier: KnownBadgeCell.reuseID)
        
        tableView.reloadData()
    }
    
    func fetchKnownBadges(){
        if let valid_id = chatID{
            vc.addLoadingView()
            API.sharedInstance.getTribeAdminBadges(
                chatID: valid_id,
                callback: { results in
                    if let mappedResults = Mapper<Badge>().mapArray(JSONObject: Array(results)) {
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
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return kRowHeight
    }
    
}
