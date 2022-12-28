//
//  BadgeManagementListDataSource.swift
//  sphinx
//
//  Created by James Carucci on 12/28/22.
//  Copyright © 2022 sphinx. All rights reserved.
//

import Foundation
import UIKit


class BadgeManagementListDataSource : NSObject{
    private var badges : [Badge]
    var vc : BadgeManagementListVC
    
    init(badges: [Badge] = [Badge](),vc:BadgeManagementListVC) {
        self.badges = badges
        self.vc = vc
    }
    
    func setupDataSource(){
        vc.badgeTableView.delegate = self
        vc.badgeTableView.dataSource = self
        vc.badgeTableView.register(UINib(nibName: "BadgeListTableViewCell", bundle: nil), forCellReuseIdentifier: "BadgeListTableViewCell")
        fetchBadges()
    }
    
    func fetchBadges(){
        //TODO: Add call to service here
        
        //Fake data here:
        let n_badges = 15
        for i in 0...n_badges{
            let new_badge = Badge()
            new_badge.name = "my_badge\(i)"
            self.badges.append(new_badge)
        }
        self.vc.badgeTableView.reloadData()
    }
}

extension BadgeManagementListDataSource : UITableViewDelegate,UITableViewDataSource{
    
    func getNBadges()->Int{
        return badges.count
    }
    
    func getBadge(index:Int)->Badge{
        return badges[index]
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return getNBadges()
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(
            withIdentifier: "BadgeListTableViewCell",
            for: indexPath
        ) as! BadgeListTableViewCell
        cell.configureCell(badge: self.getBadge(index: indexPath.row))
        return cell
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 140
    }
    
}
