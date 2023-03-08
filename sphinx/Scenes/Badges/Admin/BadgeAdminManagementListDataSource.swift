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
        
        vc.badgeTableView.register(
            UINib(nibName: "BadgeAdminListTableViewCell", bundle: nil),
            forCellReuseIdentifier: "BadgeAdminListTableViewCell"
        )
        vc.badgeTableView.register(
            UINib(nibName: "BadgeAdminListHeaderCell", bundle: nil),
            forCellReuseIdentifier: "BadgeAdminListHeaderCell"
        )
    }
    
    func fetchTemplates(){
        API.sharedInstance.getTribeAdminBadgeTemplates(
            callback: { results in
                if let mappedResults = Mapper<BadgeTemplate>().mapArray(JSONObject: Array(results)){
                    for result in mappedResults{
                        let newBadge = Badge()
                        newBadge.name = result.name
                        newBadge.icon_url = result.icon_url
                        if let req = result.rewardRequirement,
                           let type = result.rewardType,
                           let humanizedType = result.getHumanizedRewardType(){
                            newBadge.chat_id = self.chatID
                            newBadge.reward_requirement = req
                            newBadge.reward_type = type
                            newBadge.memo = "\(humanizedType) at least \(req) sats in this tribe."
                        }
                        self.badgeTemplates.append(newBadge)
                    }
                    self.vc.badgeTableView.reloadData()
                }
            },
            errorCallback: {}
        )
    }
    
    func fetchBadges(){
        API.sharedInstance.getTribeAdminBadges(
            chatID: chatID,
            callback: { results in
                if let mappedResults = Mapper<Badge>().mapArray(JSONObject: Array(results)){
                    
                    let updateResults: [Badge] = mappedResults.map({
                        $0.chat_id = self.chatID
                        return $0
                    }).sorted {
                        if ($0.activationState && $1.activationState) {
                            return ($0.name ?? "" > $1.name ?? "")
                        }
                        return ($0.activationState && !$1.activationState)
                    }
                    
                    self.badges = updateResults
                    self.vc.badgeTableView.reloadData()
                }
            },
            errorCallback: {}
        )
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
        if (indexPath.row == getNTemplates()) {
            let existingBadgeHeacerCell = UITableViewCell(frame: CGRect(x: 0, y: 0.0, width: tableView.frame.width, height: 55))
            let frame = CGRect(x: 28.0, y: 0.0, width: tableView.frame.width - 28.0, height: 55)
            existingBadgeHeacerCell.backgroundColor = UIColor.Sphinx.HeaderBG
            let label = UILabel(frame: frame)
            label.font = vc.badgeTemplateHeaderLabel.font
            label.textAlignment = .center
            label.text = "badges.manage-existing-badges".localized
            label.textColor = UIColor.Sphinx.Text
            label.textAlignment = .left
            existingBadgeHeacerCell.addSubview(label)
            existingBadgeHeacerCell.selectionStyle = .none
            return existingBadgeHeacerCell
        } else {
            return tableView.dequeueReusableCell(
                withIdentifier: "BadgeAdminListTableViewCell",
                for: indexPath
            ) as! BadgeAdminListTableViewCell
        }
    }
    
    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        if let cell = cell as? BadgeAdminListTableViewCell, indexPath.row < getNTemplates() {
            cell.configureCell(
                badge: getTemplate(index: indexPath.row),
                type: .template
            )
        } else if let cell = cell as? BadgeAdminListTableViewCell {
            let badge = self.getBadge(index: indexPath.row)
            let type : BadgeAdminCellType = (badge.activationState == true) ? .active : .inactive
            cell.configureCell(badge: self.getBadge(index: indexPath.row),type: type)
        }
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        if (indexPath.row == getNTemplates()) {
            return 55
        }
        return 140
        
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if (indexPath.row < getNTemplates()) {
            
            let badgeTypes = badges.map({ $0.reward_type })
            let templateAsBadge = getTemplate(index: indexPath.row)
            templateAsBadge.chat_id = chatID
            
            if (badgeTypes.contains(templateAsBadge.reward_type)) {
                AlertHelper.showAlert(title: "badges.cant-make-badge".localized, message: "badges.cant-make-badge-reason".localized)
            } else {
                vc.showBadgeDetail(badge: templateAsBadge,presentationContext: .template)
            }
        } else if(indexPath.row > getNTemplates()) {
            let badge = getBadge(index: indexPath.row)
            let context : BadgeDetailPresentationContext = (badge.activationState == true) ? .active : .inactive
            vc.showBadgeDetail(badge: badge, presentationContext: context)
        }
    }
}
