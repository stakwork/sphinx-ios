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
    var pageNum : Int = 1
    private lazy var spinner: UIActivityIndicatorView = makeSpinner()
    
    init(tableView:UITableView,vc:DiscoverTribesWebViewController){
        self.vc = vc
        self.tableView = tableView
        tableView.register(DiscoverTribesTableViewCell.nib, forCellReuseIdentifier: DiscoverTribesTableViewCell.reuseID)
        tableView.registerCell(LoadingMoreTableViewCell.self)
    }
    
    func fetchTribeData(searchTerm:String?=nil,shouldAppend:Bool){
        setupSpinner()
        spinner.startAnimating()
        API.sharedInstance.getTribesList(callback: { allTribes in
            self.parseIncomingTribes(allTribes: allTribes, shouldAppend:shouldAppend)
            self.spinner.isHidden = true
            self.tableView.reloadData()
        }, errorCallback: {
            self.spinner.isHidden = true
        },
        searchTerm: searchTerm,
        pageNum : pageNum
        )
    }
    
    func parseIncomingTribes(allTribes:[NSDictionary],shouldAppend:Bool){
        let results = Array(allTribes)
        if let mappedResults = Mapper<DiscoverTribeData>().mapArray(JSONObject: results){
            if shouldAppend == true{
                self.tribes += mappedResults
            }
            else{
                self.tribes = mappedResults
                self.tableView.scrollToRow(at: IndexPath(row: 0, section: 0), at: .bottom, animated: true)
            }
            tableView.reloadData()
        }
    }
    
    func performSearch(searchTerm:String?){
        pageNum = 1 // resets on search
        fetchTribeData(searchTerm: searchTerm,shouldAppend: false)
    }
    
}


extension DiscoverTribeTableViewDataSource : UITableViewDataSource{
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return tribes.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if(indexPath.row + 1  == tribes.count){
            let cell = tableView.dequeueReusableCell(withIdentifier: "LoadingMoreTableViewCell", for: indexPath) as! LoadingMoreTableViewCell
            cell.configureCell(text: "")
            cell.loadingMoreLabel.text = "Loading more tribes..."
            return cell
        }
        else{
            let cell = tableView.dequeueReusableCell(withIdentifier: "DiscoverTribesTableViewCell", for: indexPath) as! DiscoverTribesTableViewCell
            cell.configureCell(tribeData: tribes[indexPath.row])
            cell.delegate = vc
            return cell
        }
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 130.0
    }
    
    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        if indexPath.row + 1 == tribes.count {
            pageNum += 1
            fetchTribeData(searchTerm: vc.searchTextField.text, shouldAppend: true)
            print("reached the end!")
        }
    }
}

extension DiscoverTribeTableViewDataSource : UITableViewDelegate{
    
}



extension DiscoverTribeTableViewDataSource {
    func setupSpinner() {
        spinner.translatesAutoresizingMaskIntoConstraints = false
        vc.view.addSubview(spinner)

        NSLayoutConstraint.activate([
            spinner.centerXAnchor.constraint(equalTo: vc.view.centerXAnchor),
            spinner.centerYAnchor.constraint(equalTo: vc.view.centerYAnchor),
        ])
        
        spinner.startAnimating()
    }
    
    
    func makeSpinner() -> UIActivityIndicatorView {
        let spinner = UIActivityIndicatorView(style: .large)
        spinner.color = UIColor.white

        spinner.sizeToFit()
        spinner.translatesAutoresizingMaskIntoConstraints = false
        
        return spinner
    }
}
