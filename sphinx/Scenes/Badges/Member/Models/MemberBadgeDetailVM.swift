//
//  MemberBadgeDetailVM.swift
//  sphinx
//
//  Created by James Carucci on 1/30/23.
//  Copyright © 2023 sphinx. All rights reserved.
//

import Foundation
import UIKit

class MemberBadgeDetailVM : NSObject {
    
    var vc: MemberBadgeDetailVC
    var tableView: UITableView? = nil
    
    var presentationContext : MemberBadgeDetailPresentationContext
    var badgeDetailExpansionState : Bool = false

    var leaderBoardData : ChatLeaderboardEntry? = nil
    var message : TransactionMessage? = nil
    var badges : [Badge] = []
    var knownTribeBadges : [Badge] = []
    var personInfo : TribeMemberStruct? = nil
    var isModerator: Bool = false
    
    let headerOffset : Int = 0
    let badgeDetailOffset : Int = 2
    
    var isLoading : Bool {
        didSet{
            if (isLoading) {
                vc.addShimmerLoadingView()
            } else {
                vc.removeShimmerView()
            }
        }
    }
    
    init(
        vc: MemberBadgeDetailVC,
        leaderBoardData: ChatLeaderboardEntry?,
        message: TransactionMessage?,
        knownTribeBadges: [Badge]
    ) {
        self.isLoading = true
        self.vc = vc
        
        self.leaderBoardData = leaderBoardData
        self.message = message
        self.knownTribeBadges = knownTribeBadges
        
        self.presentationContext = vc.presentationContext
    }
    
    func configTable(){
        if let tableView = tableView {
            tableView.delegate = self
            tableView.dataSource = self
            
            tableView.register(UINib(nibName: "MemberBadgeHeaderCell", bundle: nil), forCellReuseIdentifier: MemberBadgeHeaderCell.reuseID)
            tableView.register(UINib(nibName: "MemberBadgeDetailTableViewCell", bundle: nil), forCellReuseIdentifier: MemberDetailTableViewCell.reuseID)
            tableView.register(UINib(nibName: "BadgeDetailCell", bundle: nil), forCellReuseIdentifier: BadgeDetailCell.reuseID)
            
            loadProfileData()
        }
    }
    
    func getCellTypeOrder() -> [MemberBadgeDetailCellType] {
        var result: [MemberBadgeDetailCellType] = [
            .header,
            .reputation,
            .contributions,
            .earnings
        ]
        
        if (badges.count > 0) {
            result.insert(.badges, at: headerOffset + 1)
        }
        
        if (badgeDetailExpansionState == true) {
            for _ in badges {
                result.insert(.details, at: badgeDetailOffset)
            }
        }
        
        return result
    }
    
    func loadProfileData() {
        guard let person = message?.person else {
            return
        }
        
        isLoading = true
        
        API.sharedInstance.getTribeMemberInfo(
            person: person,
            callback: { (success, personInfo) in
                if let personInfo = personInfo, success {
                    self.personInfo = personInfo
                    
                    if let valid_uuid = person.personUUID {
                        self.getBadgeAssets(id: valid_uuid)
                    } else {
                        self.reloadTable()
                    }
                } else {
                    self.vc.dismissView()
                }
        })
    }
    
    func getBadgeAssets(
        id:String,
        filterByThisTribeOnly: Bool = false
    ){
        API.sharedInstance.getBadgeAssets(
            user_uuid: id,
            callback: { results in
                if (filterByThisTribeOnly) {
                    let knownIds = self.knownTribeBadges.compactMap({$0.badge_id})
                    var newBadges = [Badge]()
                    for result in results{
                        if let valid_id = result.badge_id,
                           knownIds.contains(valid_id){
                            newBadges.append(result)
                        }
                    }
                    self.badges = newBadges
                } else {
                    self.badges = results
                }
                
                self.reloadTable()
                
            }, errorCallback: {}
        )
    }
    
    func reloadTable() {
        self.isLoading = false
        self.vc.dismissBadgeDetails()
        self.tableView?.reloadData()
    }
}


extension MemberBadgeDetailVM : UITableViewDelegate, UITableViewDataSource{
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        let types = getCellTypeOrder()
        let count = types.count
        
        return count
    }
    
    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        if let cell = cell as? MemberBadgeHeaderCell {
            if let personInfo = personInfo {
                cell.configureHeaderView(
                    presentingVC: vc,
                    personInfo: personInfo,
                    message: message,
                    isModerator: isModerator
                )
            }
        } else if let cell = cell as? BadgeDetailCell {
            cell.configCell(
                badge: badges[indexPath.row - badgeDetailOffset]
            )
        } else if let cell = cell as? MemberDetailTableViewCell {
            cell.configureCell(
                type: getCellTypeOrder()[indexPath.row],
                badges: badges,
                leaderboardData: leaderBoardData,
                isExpanded: badgeDetailExpansionState
            )
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cellTypes = getCellTypeOrder()
        let cellType = cellTypes[indexPath.row]
        
        if (cellType == .header){
            return tableView.dequeueReusableCell(
                withIdentifier: MemberBadgeHeaderCell.reuseID,
                for: indexPath
            ) as! MemberBadgeHeaderCell
        } else if (cellType == .details) {
            return tableView.dequeueReusableCell(
                withIdentifier: BadgeDetailCell.reuseID,
                for: indexPath
            ) as! BadgeDetailCell
        } else {
            return tableView.dequeueReusableCell(
                withIdentifier: MemberDetailTableViewCell.reuseID,
                for: indexPath
            ) as! MemberDetailTableViewCell
        }
        
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if(getCellTypeOrder()[indexPath.row] == .badges){
            (badgeDetailExpansionState == false) ? vc.expandBadgeDetail() : vc.dismissBadgeDetails()
            badgeDetailExpansionState = !badgeDetailExpansionState
            tableView.reloadData()
        }
    }
}




