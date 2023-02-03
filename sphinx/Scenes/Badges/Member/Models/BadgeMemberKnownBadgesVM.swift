//
//  BadgeMemberKnownBadgesVM.swift
//  sphinx
//
//  Created by James Carucci on 2/2/23.
//  Copyright © 2023 sphinx. All rights reserved.
//

import Foundation
import UIKit

class BadgeMemberKnownBadgesVM : NSObject {
    
    var tableView : UITableView
    var vc : BadgeMemberKnownBadgesVC
    
    init(vc: BadgeMemberKnownBadgesVC, tableView: UITableView) {
        self.vc = vc
        self.tableView = tableView
    }
    
    func configureTable(){
        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(UINib(nibName: "KnownBadgeCell", bundle: nil), forCellReuseIdentifier: KnownBadgeCell.reuseID)
        
        tableView.reloadData()
    }
    
}


extension BadgeMemberKnownBadgesVM : UITableViewDelegate, UITableViewDataSource{
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 3
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = UITableViewCell()
        let label = UILabel(frame: CGRect(x: 0.0, y: 0.0, width: 100.0, height: cell.frame.height))
        var text = ""
        for _ in 0..<10{
            text += "\(indexPath.row)"
        }
        label.text = text
        cell.addSubview(label)
        return cell
    }
    
    
}
