//
//  FeedItemDetailVM_Q12023.swift
//  sphinx
//
//  Created by James Carucci on 3/2/23.
//  Copyright © 2023 sphinx. All rights reserved.
//

import Foundation
import UIKit

class FeedItemDetailVM_Q12023 : NSObject{
    
    weak var vc: FeedItemDetailVC_Q12023?
    weak var tableView:UITableView?
    
    init(vc:FeedItemDetailVC_Q12023,tableView:UITableView){
        self.vc = vc
        self.tableView = tableView
    }
    
    func setupTableView(){
        tableView?.register(UINib(nibName: "FeedItemDetailHeaderCellQ123", bundle: nil), forCellReuseIdentifier: FeedItemDetailHeaderCellQ123.reuseID)
        
        tableView?.delegate = self
        tableView?.dataSource = self
    }
    
}

extension FeedItemDetailVM_Q12023 : UITableViewDelegate, UITableViewDataSource{
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(
            withIdentifier: FeedItemDetailHeaderCellQ123.reuseID,
            for: indexPath
        ) as! FeedItemDetailHeaderCellQ123
        return cell
    }
    
    
}
