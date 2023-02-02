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
    func reloadHeaderView(personInfo:TribeMemberStruct)
    func getImageViewReference()->UIImageView
}

class MemberBadgeDetailVM : NSObject {
    var vc: MemberBadgeDetailVC
    var tableView: UITableView
    var presentationContext : MemberBadgeDetailPresentationContext
    var badgeDetailExpansionState : Bool = false
    var message : TransactionMessage? = nil
    var badges : [Badge] = []
    let headerOffset : Int = 0
    let badgeDetailOffset : Int = 2
    var delegate: MemberBadgeDetailVMDisplayDelegate? = nil
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
        
        //DispatchQueue.main.asyncAfter(deadline: .now() + 3.0, execute: {
            self.loadBadges()
        //})
        
        loadProfileData()
        
        tableView.reloadData()
    }
    
    func loadBadges(){
        //TODO: replace with API call
        let badge = Badge()
        badge.name = "Early Adopter"
        badge.icon_url = "https://i.ibb.co/Ch8mwg0/badge-Example.png"
        let badge2 = Badge()
        badge2.name = "Whale!"
        badge2.icon_url = "https://i.ibb.co/0Bs3Xsk/badge-example2.png"
        self.badges = [
            badge,
            badge2,
            badge,
            badge2,
            badge
        ]
        
        vc.dismissBadgeDetails()
        tableView.reloadData()
    }
    
    func getCellTypeOrder() -> [MemberBadgeDetailCellType] {
        var result = [MemberBadgeDetailCellType]()
        result = [
            .header,
            .posts,
            .contributions,
            .earnings
        ]
        if(badges.count > 0){
            result.insert(.badges, at: headerOffset + 1)
        }
        
        if(badgeDetailExpansionState == true){
            for badge in badges{
                result.insert(.details, at: badgeDetailOffset)
            }
        }
        
        return result
    }
    
    func configHeaderView(personInfo:TribeMemberStruct){
        print(personInfo)
        delegate?.reloadHeaderView(personInfo: personInfo)
        let iv = delegate?.getImageViewReference()
        iv?.sd_setImage(with: URL(string: personInfo.img))
    }
    
    func loadProfileData() {
        guard let person = message?.person else {
            vc.dismiss(animated: true)
            return
        }
        
        isLoading = true
        //Fake 10s delay for debug
        //DispatchQueue.main.asyncAfter(deadline: .now() + 10.0, execute: {
            API.sharedInstance.getTribeMemberInfo(person: person, callback: { (success, personInfo) in
                if let personInfo = personInfo, success {
                    self.isLoading = false
                    self.configHeaderView(personInfo: personInfo)
                } else {
                    //self.dismissView()
                }
            })
        //})
        
    }
    
}


extension MemberBadgeDetailVM : UITableViewDelegate,UITableViewDataSource{
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        let types = getCellTypeOrder()
        let count = types.count
        if(types.contains({MemberBadgeDetailCellType.earnings}()) == false){
            print("failed to add earnings")
        }
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
            cell.initHeaderView()
            
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
            cell.configureCell(type: getCellTypeOrder()[indexPath.row], badges: badges,isExpanded: badgeDetailExpansionState)
            
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




