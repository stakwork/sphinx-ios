//
//  BadgeMemberKnownBadgesVM.swift
//  sphinx
//
//  Created by James Carucci on 2/2/23.
//  Copyright © 2023 sphinx. All rights reserved.
//

import Foundation
import UIKit

class BadgeMemberKnownBadgesVM : NSObject {
    
    var tableView : UITableView
    var vc : BadgeMemberKnownBadgesVC
    var knownBadges : [Badge] = []
    
    init(vc: BadgeMemberKnownBadgesVC, tableView: UITableView) {
        self.vc = vc
        self.tableView = tableView
    }
    
    func configureTable(){
        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(UINib(nibName: "KnownBadgeCell", bundle: nil), forCellReuseIdentifier: KnownBadgeCell.reuseID)
        
        fetchKnownBadges()
        
        tableView.reloadData()
    }
    
    func fetchKnownBadges(){
        let badge = Badge()
        badge.name = "my badge"
        badge.memo = "dexription of my badge"
        badge.icon_url = "https://i.ibb.co/Ch8mwg0/badge-Example.png"
        knownBadges.append(badge)
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
