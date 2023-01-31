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
    var tableView: UITableView
    var presentationContext : MemberBadgeDetailPresentationContext
    var badgeDetailExpansionState : Bool = false
    
    init(vc: MemberBadgeDetailVC, tableView: UITableView) {
        self.vc = vc
        self.tableView = tableView
        self.presentationContext = vc.presentationContext
    }
    
    func configTable(){
        tableView.delegate = self
        tableView.dataSource = self
        
        tableView.register(UINib(nibName: "MemberBadgeDetailTableViewCell", bundle: nil), forCellReuseIdentifier: MemberDetailTableViewCell.reuseID)
        tableView.register(UINib(nibName: "BadgeDetailCell", bundle: nil), forCellReuseIdentifier: BadgeDetailCell.reuseID)
        
        tableView.reloadData()
    }
    
    func getCellTypeOrder() -> [MemberBadgeDetailCellType] {
        switch(presentationContext){
        case .member:
            return [
                .posts,
                .contributions,
                .earnings
            ]
            break
        case .admin:
            return [
                .badges,
                .posts,
                .contributions,
                .earnings
            ]
            break
        }
    }
    
}


extension MemberBadgeDetailVM : UITableViewDelegate,UITableViewDataSource{
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return getCellTypeOrder().count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        if(indexPath.row == 1 && badgeDetailExpansionState == true){
            let cell = tableView.dequeueReusableCell(
                withIdentifier: BadgeDetailCell.reuseID,
                for: indexPath
            ) as! BadgeDetailCell
            //cell.configureCell(type: getCellTypeOrder()[indexPath.row])
            cell.configCell()
            
            return cell
        }
        else{
            let cell = tableView.dequeueReusableCell(
                withIdentifier: MemberDetailTableViewCell.reuseID,
                for: indexPath
            ) as! MemberDetailTableViewCell
            cell.configureCell(type: getCellTypeOrder()[indexPath.row])
            
            return cell
        }
        
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if(indexPath.row == 0){
            (badgeDetailExpansionState == false) ? vc.expandBadgeDetail() : vc.dismissBadgeDetails()
            tableView.reloadData()
            badgeDetailExpansionState = !badgeDetailExpansionState
        }
    }
    
    
}
