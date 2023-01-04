//
//  DiscoverTribesTableViewDataSource.swift
//  sphinx
//
//  Created by James Carucci on 1/4/23.
//  Copyright © 2023 sphinx. All rights reserved.
//

import Foundation
import UIKit
import ObjectMapper


class DiscoverTribeTableViewDataSource : NSObject{
    var tableView : UITableView
    var vc : DiscoverTribesWebViewController
    var tribes = [DiscoverTribeData]()
    
    init(tableView:UITableView,vc:DiscoverTribesWebViewController){
        self.vc = vc
        self.tableView = tableView
        tableView.register(DiscoverTribesTableViewCell.nib, forCellReuseIdentifier: DiscoverTribesTableViewCell.reuseID)
    }
    
    func fetchTribeData(){
        API.sharedInstance.getAllTribes(callback: { allTribes in
            self.filterTribes(allTribes: allTribes)
        }, errorCallback: {
            //completion()
        })
    }
    
    func filterTribes(allTribes:[NSDictionary]){
        let tribesLimit = 50
        let results = Array(allTribes[0..<min(tribesLimit,allTribes.count)])
        if let mappedResults = Mapper<DiscoverTribeData>().mapArray(JSONObject: results){
            self.tribes = mappedResults
            tableView.reloadData()
        }
    }
    
}


extension DiscoverTribeTableViewDataSource : UITableViewDataSource{
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return tribes.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "DiscoverTribesTableViewCell", for: indexPath) as! DiscoverTribesTableViewCell
        cell.configureCell(tribeData: tribes[indexPath.row])
        cell.delegate = vc
        return cell
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 130.0
    }
}

extension DiscoverTribeTableViewDataSource : UITableViewDelegate{
    
}

