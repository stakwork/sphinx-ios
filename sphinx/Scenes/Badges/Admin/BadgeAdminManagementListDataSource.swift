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
    private var badgeTemplates : [Badge] = [Badge]()
    private var badges : [Badge] =  [Badge]()
    var vc : BadgeAdminManagementListVC
    var chatID : Int?
    
    init(vc:BadgeAdminManagementListVC,chatID:Int?) {
        self.vc = vc
        self.chatID = chatID
    }
    
    func setupDataSource(){
        vc.badgeTableView.delegate = self
        vc.badgeTableView.dataSource = self
        vc.badgeTableView.register(UINib(nibName: "BadgeAdminListTableViewCell", bundle: nil), forCellReuseIdentifier: "BadgeAdminListTableViewCell")
        vc.badgeTableView.register(UINib(nibName: "BadgeAdminListHeaderCell", bundle: nil), forCellReuseIdentifier: "BadgeAdminListHeaderCell")
        fetchTemplates()
        fetchBadges()
    }
    
    func fetchTemplates(){
        API.sharedInstance.getTribeAdminBadgeTemplates(
            callback: {results in
                if let mappedResults = Mapper<BadgeTemplate>().mapArray(JSONObject: Array(results)){
                    print(mappedResults)
                    for result in mappedResults{
                        let newBadge = Badge()
                        newBadge.name = result.name
                        newBadge.icon_url = result.icon_url
                        if let req = result.rewardRequirement,
                           let type = result.getHumanizedRewardType(){
                            newBadge.requirements = "\(type) at least \(req) sats in this tribe."
                        }
                        self.badgeTemplates.append(newBadge)
                    }
                    self.vc.badgeTableView.reloadData()
                }
            },
            errorCallback: {
                print("error")
        })
    }
    
    func fetchBadges(){
        
        API.sharedInstance.getTribeAdminBadges(
            tribeID: nil,
            callback: { results in
               print(results)
                if let mappedResults = Mapper<Badge>().mapArray(JSONObject: Array(results)){
                    self.badges = mappedResults
                }
            },
            errorCallback: {
                
            })
        /*
        let new_badge3 = Badge()
        new_badge3.name = "1k Spend Club"
        new_badge3.icon_url = "https://i.ibb.co/2nvyW7t/1k-badge.png"
        new_badge3.requirements = "Spend at least 1k in the Tribe."
        new_badge3.amount_issued = 100
        new_badge3.amount_created = 1000
        self.badges.append(new_badge3)
         */
        
        self.vc.badgeTableView.reloadData()
    }
}

extension BadgeAdminManagementListDataSource : UITableViewDelegate,UITableViewDataSource{
    
    func getNBadges()->Int{
        return badges.count
    }
    
    func getNTemplates() -> Int{
        return badgeTemplates.count
    }
    
    func getBadge(index:Int)->Badge{
        return badges[index - getNTemplates() - 1]
    }
    
    func getTemplate(index:Int)->Badge{
        return badgeTemplates[index]
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return getNBadges() + getNTemplates() + ((badges.count > 0) ? 1 : 0)
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if(indexPath.row < getNTemplates()){
            let cell = tableView.dequeueReusableCell(
                withIdentifier: "BadgeAdminListTableViewCell",
                for: indexPath
            ) as! BadgeAdminListTableViewCell
            cell.configureCell(badge: self.getTemplate(index: indexPath.row),type: .template)
            return cell
        }
        else if(indexPath.row == getNTemplates()){
            //header view
            let existingBadgeHeacerCell = UITableViewCell(frame: CGRect(x: 0.0, y: 0.0, width: tableView.frame.width, height: 55))
            let frame = CGRect(x: 0.0, y:0.0 , width: existingBadgeHeacerCell.frame.width, height: existingBadgeHeacerCell.frame.height)
            existingBadgeHeacerCell.backgroundColor = UIColor.Sphinx.Body
            let label = UILabel(frame: frame)
            label.font = vc.badgeTemplateHeaderLabel.font
            label.textAlignment = .center
            label.text = "Manage Existing Badges"
            label.textColor = UIColor.Sphinx.BodyInverted
            existingBadgeHeacerCell.addSubview(label)
            existingBadgeHeacerCell.selectionStyle = .none
            return existingBadgeHeacerCell
        }
        else{
            let cell = tableView.dequeueReusableCell(
                withIdentifier: "BadgeAdminListTableViewCell",
                for: indexPath
            ) as! BadgeAdminListTableViewCell
            cell.configureCell(badge: self.getBadge(index: indexPath.row),type: .active)
            return cell
        }
        
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        if(indexPath.row == getNTemplates()){
            return 55
        }
        return 140
        
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if(indexPath.row < getNTemplates()){
            vc.showBadgeDetail(badge: getTemplate(index: indexPath.row),presentationContext: .template)
        }
        else if(indexPath.row > getNTemplates()){
            vc.showBadgeDetail(badge: getBadge(index: indexPath.row), presentationContext: .existing)
            //TODO: set it up for badge assets
        }
        
    }
    
    
}
