//
//  MemberBadgeDetailVM.swift
//  sphinx
//
//  Created by James Carucci on 1/30/23.
//  Copyright © 2023 sphinx. All rights reserved.
//

import Foundation
import UIKit

protocol MemberBadgeDetailVMDisplayDelegate{
    func reloadHeaderView(personInfo:TribeMemberStruct,message:TransactionMessage?)
    func getImageViewReference()->UIImageView
}

class MemberBadgeDetailVM : NSObject {
    var vc: MemberBadgeDetailVC
    var tableView: UITableView
    var presentationContext : MemberBadgeDetailPresentationContext
    var badgeDetailExpansionState : Bool = false
    var message : TransactionMessage? = nil
    var badges : [Badge] = []
    var knownTribeBadges : [Badge] = []
    let headerOffset : Int = 0
    let badgeDetailOffset : Int = 2
    var delegate: MemberBadgeDetailVMDisplayDelegate? = nil
    var leaderBoardData : ChatLeaderboardEntry? = nil
    var isLoading : Bool {
        didSet{
            if(isLoading){
                vc.addShimmerLoadingView()
            }
            else{
                vc.removeShimmerView()
            }
        }
    }
    
    init(vc: MemberBadgeDetailVC, tableView: UITableView) {
        self.isLoading = false
        self.vc = vc
        self.tableView = tableView
        self.presentationContext = vc.presentationContext
    }
    
    func configTable(){
        tableView.delegate = self
        tableView.dataSource = self
        
        tableView.register(UINib(nibName: "MemberBadgeHeaderCell", bundle: nil), forCellReuseIdentifier: MemberBadgeHeaderCell.reuseID)
        tableView.register(UINib(nibName: "MemberBadgeDetailTableViewCell", bundle: nil), forCellReuseIdentifier: MemberDetailTableViewCell.reuseID)
        tableView.register(UINib(nibName: "BadgeDetailCell", bundle: nil), forCellReuseIdentifier: BadgeDetailCell.reuseID)
        
        loadProfileData()
        
        tableView.reloadData()
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
        
        if(badgeDetailExpansionState == true){
            for _ in badges {
                result.insert(.details, at: badgeDetailOffset)
            }
        }
        
        return result
    }
    
    func configHeaderView(personInfo:TribeMemberStruct,message:TransactionMessage?){
        print(personInfo)
        delegate?.reloadHeaderView(personInfo: personInfo, message: message)
        let iv = delegate?.getImageViewReference()
        iv?.sd_setImage(with: URL(string: personInfo.img))
    }
    
    func loadProfileData() {
        guard let person = message?.person else {
            //vc.dismiss(animated: true)
            return
        }
        
        isLoading = true
        
        API.sharedInstance.getTribeMemberInfo(person: person, callback: { (success, personInfo) in
            if let personInfo = personInfo, success {
                self.isLoading = false
                self.configHeaderView(personInfo: personInfo,message: self.message)
                if let valid_uuid = person.personUUID{
                    self.getBadgeAssets(id: valid_uuid)
                }
            } else {
                //TODO: error handling? Timeout?
            }
        })
    }
    
    func getBadgeAssets(id:String,filterByThisTribeOnly:Bool=false){
        API.sharedInstance.getBadgeAssets(
            user_uuid: id,
            callback: { results in
                print(results)
                if(filterByThisTribeOnly){
                    let knownIds = self.knownTribeBadges.compactMap({$0.badge_id})
                    var newBadges = [Badge]()
                    for result in results{
                        if let valid_id = result.badge_id,
                           knownIds.contains(valid_id){
                            newBadges.append(result)
                        }
                    }
                    self.badges = newBadges
                }
                else{
                    self.badges = results
                }
                
                self.vc.dismissBadgeDetails()
                self.tableView.reloadData()
            },
            errorCallback: {
                
            })
    }
}




extension MemberBadgeDetailVM : UITableViewDelegate,UITableViewDataSource{
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        let types = getCellTypeOrder()
        let count = types.count
        if(types.contains({MemberBadgeDetailCellType.earnings}()) == false){
            print("failed to add earnings")
        }
        print("\n\n\nNUM CELLS COUNT:\(count) @\(Date().timeIntervalSince1970)\n\n\n")
        
        return count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cellTypes = getCellTypeOrder()
        let cellType = cellTypes[indexPath.row]
        if(cellType == .header){
            
            let cell = tableView.dequeueReusableCell(
                withIdentifier: MemberBadgeHeaderCell.reuseID,
                for: indexPath
            ) as! MemberBadgeHeaderCell
            
            self.delegate = cell
            cell.initHeaderView(presentingVC: vc)
            cell.moderatorBadgeImageView.isHidden = vc.isModerator == false
            cell.moderatorLabel.isHidden = vc.isModerator == false
            
            return cell
        }
        else if(cellType == .details){
            let cell = tableView.dequeueReusableCell(
                withIdentifier: BadgeDetailCell.reuseID,
                for: indexPath
            ) as! BadgeDetailCell
            cell.configCell(badge: badges[indexPath.row - badgeDetailOffset])
            
            return cell
        }
        else{
            let cell = tableView.dequeueReusableCell(
                withIdentifier: MemberDetailTableViewCell.reuseID,
                for: indexPath
            ) as! MemberDetailTableViewCell
            cell.configureCell(type: getCellTypeOrder()[indexPath.row], badges: badges, leaderboardData: leaderBoardData,isExpanded: badgeDetailExpansionState)
            
            return cell
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




