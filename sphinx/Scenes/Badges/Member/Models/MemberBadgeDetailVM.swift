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
    
    
    
    init(vc: MemberBadgeDetailVC, tableView: UITableView) {
        self.vc = vc
        self.tableView = tableView
        self.presentationContext = vc.presentationContext
    }
    
    func configTable(){
        tableView.delegate = self
        tableView.dataSource = self
        
        tableView.register(UINib(nibName: "MemberBadgeDetailTableViewCell", bundle: nil), forCellReuseIdentifier: MemberBadgeDetailTableViewCell.reuseID)
        
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
        
        let cell = tableView.dequeueReusableCell(
            withIdentifier: MemberBadgeDetailTableViewCell.reuseID,
            for: indexPath
        ) as! MemberBadgeDetailTableViewCell
        cell.configureCell(type: getCellTypeOrder()[indexPath.row])
        
        return cell
    }
    
    
}
