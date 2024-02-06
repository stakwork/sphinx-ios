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
    var displayedTribes = [DiscoverTribeData]()
    var tribes = [DiscoverTribeData]()
    var pageNum : Int = 1
    var itemsPerPage : Int = 20
    var loadingWheelCell : Int = 0
    
    private lazy var spinner: UIActivityIndicatorView = makeSpinner()
    lazy var joinedChatIds : [String] = {
        return Chat.getAllTribes().compactMap({ $0.uuid ?? "" }).filter({ $0.isNotEmpty })
    }()
    
    lazy var joinedChatPubkeys : [String] = {
        return Chat.getAllTribes().compactMap({ $0.ownerPubkey ?? "" }).filter({ $0.isNotEmpty })
    }()
    
    init(tableView:UITableView,vc:DiscoverTribesWebViewController){
        self.vc = vc
        self.tableView = tableView
        tableView.register(DiscoverTribesTableViewCell.nib, forCellReuseIdentifier: DiscoverTribesTableViewCell.reuseID)
        tableView.registerCell(LoadingMoreTableViewCell.self)
        tableView.separatorColor = .clear
    }
    
    func fetchTribeData(
        searchTerm: String? = nil,
        tags:[String] = []
    ){
        setupSpinner()
        spinner.startAnimating()
        
        API.sharedInstance.getTribesList(
            callback: { allTribes in
                self.parseIncomingTribes(allTribes: allTribes, shouldAppend: self.pageNum > 1)
                self.spinner.isHidden = true
                self.tableView.reloadData()
            }, errorCallback: {
                self.spinner.isHidden = true
            },
            limit: itemsPerPage,
            searchTerm: searchTerm,
            page: pageNum,
            tags:tags
        )
    }
    
    func parseIncomingTribes(allTribes:[NSDictionary],shouldAppend:Bool){
        let results = Array(allTribes)
        
        loadingWheelCell = allTribes.count == itemsPerPage ? 1 : 0
        
        if let mappedResults = Mapper<DiscoverTribeData>().mapArray(JSONObject: results){
            if shouldAppend {
                tribes += mappedResults
            } else{
                tribes = mappedResults
            }
            displayedTribes = tribes
            tableView.reloadData()
            tableView.isHidden = tribes.isEmpty
            
            if tableView.numberOfRows(inSection: 0) > 0 && !shouldAppend {
                tableView.scrollToRow(at: IndexPath(row: 0, section: 0), at: .bottom, animated: true)
            }
        }
    }
    
    func applyTags(
        searchTerm: String?,
        tags: [String]
    ){
        pageNum = 1
        fetchTribeData(searchTerm: searchTerm, tags: tags)
    }
    
    func performSearch(
        searchTerm: String?,
        tags: [String]
    ){
        if(searchTerm == nil || searchTerm == ""){
            displayedTribes = tribes
        }
        else if let searchTerm = searchTerm{
            displayedTribes = tribes.filter({
                if let name = $0.name?.lowercased(){
                    return name.contains(searchTerm.lowercased())
                }
                return false
            })
        }
        
        tableView.reloadData()
    }
}

extension DiscoverTribeTableViewDataSource : UITableViewDataSource, UITableViewDelegate {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return displayedTribes.count //+ loadingWheelCell
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if (indexPath.row  == displayedTribes.count) {
            let cell = tableView.dequeueReusableCell(withIdentifier: "LoadingMoreTableViewCell", for: indexPath) as! LoadingMoreTableViewCell
            cell.configureCell(text: "")
            cell.loadingMoreLabel.text = "Loading..."
            cell.loadingMoreLabel.font = UIFont(name: "Roboto", size: 14.0)
            cell.loadingMoreLabel.textColor = UIColor.Sphinx.SecondaryText
            return cell
        } else {
            let tribeOfInterest = displayedTribes[indexPath.row]
            let wasJoined = joinedChatIds.contains(tribeOfInterest.uuid ?? "") || joinedChatPubkeys.contains(tribeOfInterest.pubkey ?? "")
            let cell = tableView.dequeueReusableCell(withIdentifier: "DiscoverTribesTableViewCell", for: indexPath) as! DiscoverTribesTableViewCell
            cell.configureCell(tribeData: tribeOfInterest,wasJoined: wasJoined)
            cell.delegate = vc
            return cell
        }
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        if (indexPath.row  == displayedTribes.count) {
            return 50.0
        } else {
            return 130.0
        }
    }
    
    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        if indexPath.row == displayedTribes.count {
            pageNum += 1
            
            fetchTribeData(
                searchTerm: vc.searchTextField.text,
                tags: []
            )
        }
    }
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
        let spinner = UIActivityIndicatorView(style: .medium)
        spinner.color = UIColor.white

        spinner.sizeToFit()
        spinner.translatesAutoresizingMaskIntoConstraints = false
        
        return spinner
    }
}
