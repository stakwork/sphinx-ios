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
    
    init(vc: MemberBadgeDetailVC, tableView: UITableView) {
        self.vc = vc
        self.tableView = tableView
    }
    
    func configTable(){
        tableView.delegate = self
        tableView.dataSource = self
        
        tableView.register(UINib(nibName: "MemberBadgeDetailTableViewCell", bundle: nil), forCellReuseIdentifier: MemberBadgeDetailTableViewCell.reuseID)
        
        tableView.reloadData()
    }
    
}


extension MemberBadgeDetailVM : UITableViewDelegate,UITableViewDataSource{
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 3
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        /*
        let cell = UITableViewCell()
        let label = UILabel(frame: CGRect(x: 0.0, y: 0.0, width: cell.frame.width, height: cell.frame.height))
        label.text = "\(indexPath.row)"
        label.textColor = UIColor.Sphinx.BodyInverted
        cell.addSubview(label)
        */
        
        let cell = tableView.dequeueReusableCell(
            withIdentifier: MemberBadgeDetailTableViewCell.reuseID,
            for: indexPath
        ) as! MemberBadgeDetailTableViewCell
        
        return cell
    }
    
    
}
