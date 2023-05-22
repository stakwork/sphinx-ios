//
//  ProfileManageStorageViewModel.swift
//  sphinx
//
//  Created by James Carucci on 5/22/23.
//  Copyright © 2023 sphinx. All rights reserved.
//

import Foundation
import UIKit

class ProfileManageStorageViewModel : NSObject{
    var vc : ProfileManageStorageViewController
    var tableView:UITableView
    var mediaTypes = StorageManagerMediaType.allCases
    
    init(
        vc:ProfileManageStorageViewController,
        tableView:UITableView
    ){
        self.vc = vc
        self.tableView = tableView
    }
    
    func finishSetup(){
        self.tableView.delegate = self
        self.tableView.dataSource = self
        
        tableView.register(UINib(nibName: "MediaStorageTypeSummaryTableViewCell", bundle: nil), forCellReuseIdentifier: MediaStorageTypeSummaryTableViewCell.reuseID)
    }
    
    
}

extension ProfileManageStorageViewModel : UITableViewDelegate,UITableViewDataSource{
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(
            withIdentifier: MediaStorageTypeSummaryTableViewCell.reuseID,
            for: indexPath
        ) as! MediaStorageTypeSummaryTableViewCell
        cell.finishSetup()
        cell.setupAsMediaType(type: mediaTypes[indexPath.row])
        return cell
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return mediaTypes.count
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        // Specify the desired height for your cells
        return 64.0 // Adjust this value according to your requirements
    }
}
