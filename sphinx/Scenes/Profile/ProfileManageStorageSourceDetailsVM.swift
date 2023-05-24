//
//  ProfileManageStorageSourceDetailsVM.swift
//  sphinx
//
//  Created by James Carucci on 5/23/23.
//  Copyright © 2023 sphinx. All rights reserved.
//

import Foundation
import UIKit

class ProfileManageStorageSourceDetailsVM : NSObject{
    
    var vc : ProfileManageStorageSourceDetailsVC
    var tableView: UITableView
    
    init(vc:ProfileManageStorageSourceDetailsVC,tableView:UITableView){
        self.vc = vc
        self.tableView = tableView
    }
    
    func finishSetup(){
        tableView.delegate = self
        tableView.dataSource = self
        
        tableView.register(UINib(nibName: "MediaStorageSourceTableViewCell", bundle: nil), forCellReuseIdentifier: MediaStorageSourceTableViewCell.reuseID)
    }
    
}

extension ProfileManageStorageSourceDetailsVM : UITableViewDelegate,UITableViewDataSource{
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 50
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(
            withIdentifier: MediaStorageSourceTableViewCell.reuseID,
            for: indexPath
        ) as! MediaStorageSourceTableViewCell
        return cell
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        // Specify the desired height for your cells
        return 64.0 // Adjust this value according to your requirements
    }
}
