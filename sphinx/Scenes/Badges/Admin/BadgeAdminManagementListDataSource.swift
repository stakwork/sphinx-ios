//
//  BadgeManagementListDataSource.swift
//  sphinx
//
//  Created by James Carucci on 12/28/22.
//  Copyright © 2022 sphinx. All rights reserved.
//

import Foundation
import UIKit
import ObjectMapper


class BadgeAdminManagementListDataSource : NSObject{
    private var badges : [Badge]
    var vc : BadgeAdminManagementListVC
    
    init(badges: [Badge] = [Badge](),vc:BadgeAdminManagementListVC) {
        self.badges = badges
        self.vc = vc
    }
    
    func setupDataSource(){
        vc.badgeTableView.delegate = self
        vc.badgeTableView.dataSource = self
        vc.badgeTableView.register(UINib(nibName: "BadgeAdminListTableViewCell", bundle: nil), forCellReuseIdentifier: "BadgeAdminListTableViewCell")
        fetchBadges()
    }
    
    func fetchBadges(){
        //TODO: Add call to service here
        /*
        API.sharedInstance.getTribeAdminBadges(
            tribeID: "",
            callback: { results in
                if let badgeResults = Mapper<Badge>().mapArray(JSONObject: results){
                    self.badges = badgeResults
                    self.vc.badgeTableView.reloadData()
                }
                else{
                    self.vc.showErrorMessage()
                }
            
        },
        errorCallback: {
            self.vc.showErrorMessage()
        })
        */
        //Fake data here:
        let new_badge = Badge()
        new_badge.name = "1k Spend Club"
        new_badge.icon_url = "https://i.ibb.co/2nvyW7t/1k-badge.png"
        new_badge.requirements = "Spend at least 1k in the Tribe."
        self.badges.append(new_badge)
        
        let new_badge2 = Badge()
        new_badge2.name = "1k Earn Club"
        new_badge2.icon_url = "https://i.ibb.co/2nvyW7t/1k-badge.png"
        new_badge2.requirements = "Earn at least 1k in the Tribe."
        self.badges.append(new_badge2)
        
        
        self.vc.badgeTableView.reloadData()
    }
}

extension BadgeAdminManagementListDataSource : UITableViewDelegate,UITableViewDataSource{
    
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
            withIdentifier: "BadgeAdminListTableViewCell",
            for: indexPath
        ) as! BadgeAdminListTableViewCell
        cell.configureCell(badge: self.getBadge(index: indexPath.row))
        return cell
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 140
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        vc.showBadgeDetail(badge: getBadge(index: indexPath.row))
    }
    
    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        if(vc.viewDidLayout == false){
            return
        }
        if indexPath.row + 1 > 5 {
            print("leaving initial view")
            vc.animateHeader(shouldAppear: false)
        }
        else if (indexPath.row == 0){
            print("showing initial view")
            vc.animateHeader(shouldAppear: true)
        }
        print("willDisplay:\(indexPath.row)")
    }
    
}
