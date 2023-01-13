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
    var itemsPerPage : Int = 20
    var loadingWheelCell : Int = 0
    
    private lazy var spinner: UIActivityIndicatorView = makeSpinner()
    lazy var joinedChatIds : [String] = {
        let contactsService = ContactsService()
        return contactsService
            .getChatListObjects()
            .filter { $0.isPublicGroup() }.compactMap({$0.getChat()?.uuid})
    }()
    
    init(tableView:UITableView,vc:DiscoverTribesWebViewController){
        self.vc = vc
        self.tableView = tableView
        tableView.register(DiscoverTribesTableViewCell.nib, forCellReuseIdentifier: DiscoverTribesTableViewCell.reuseID)
        tableView.registerCell(LoadingMoreTableViewCell.self)
    }
    
    func fetchTribeData(
        searchTerm: String? = nil,
        shouldAppend: Bool
    ){
        setupSpinner()
        spinner.startAnimating()
        
        API.sharedInstance.getTribesList(
            callback: { allTribes in
                self.parseIncomingTribes(allTribes: allTribes, shouldAppend: shouldAppend)
                self.spinner.isHidden = true
                self.tableView.reloadData()
            }, errorCallback: {
                self.spinner.isHidden = true
            },
            limit: itemsPerPage,
            searchTerm: searchTerm,
            page: pageNum
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
            tableView.reloadData()
            tableView.isHidden = tribes.isEmpty
            
            if tableView.numberOfRows(inSection: 0) > 0 && !shouldAppend {
                tableView.scrollToRow(at: IndexPath(row: 0, section: 0), at: .bottom, animated: true)
            }
        }
    }
    
    func performSearch(searchTerm:String?){
        pageNum = 1
        fetchTribeData(searchTerm: searchTerm, shouldAppend: false)
    }
}

extension DiscoverTribeTableViewDataSource : UITableViewDataSource, UITableViewDelegate {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return tribes.count + loadingWheelCell
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if (indexPath.row  == tribes.count) {
            let cell = tableView.dequeueReusableCell(withIdentifier: "LoadingMoreTableViewCell", for: indexPath) as! LoadingMoreTableViewCell
            cell.configureCell(text: "")
            cell.loadingMoreLabel.text = "Loading more tribes..."
            return cell
        } else {
            let tribeOfInterest = tribes[indexPath.row]
            let wasJoined = joinedChatIds.contains(tribeOfInterest.uuid ?? "")
            let cell = tableView.dequeueReusableCell(withIdentifier: "DiscoverTribesTableViewCell", for: indexPath) as! DiscoverTribesTableViewCell
            cell.configureCell(tribeData: tribeOfInterest,wasJoined: wasJoined)
            cell.delegate = vc
            return cell
        }
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        if (indexPath.row  == tribes.count) {
            return 50.0
        } else {
            return 130.0
        }
    }
    
    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        if indexPath.row == tribes.count {
            pageNum += 1
            fetchTribeData(searchTerm: vc.searchTextField.text, shouldAppend: true)
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
