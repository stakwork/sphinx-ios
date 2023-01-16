//
//  DiscoverTribesWkWebView.swift
//  sphinx
//
//  Created by James Carucci on 1/2/23.
//  Copyright © 2023 sphinx. All rights reserved.
//

import Foundation
import UIKit


protocol DiscoverTribesWVVCDelegate{
    func handleDeeplinkClick()
}

extension DashboardRootViewController : DiscoverTribesWVVCDelegate{
    func handleDeeplinkClick() {
        self.handleDeepLinksAndPush()
    }
}

class DiscoverTribesWebViewController : UIViewController{
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var searchBar: UIView!
    @IBOutlet weak var searchTextField: UITextField!
    @IBOutlet weak var searchBarContainer: UIView!
    @IBOutlet weak var tagsButton: UIButton!
    @IBOutlet weak var tagCountContainerView: UIView!
    @IBOutlet weak var tagCountLabel: UILabel!
    
    var currentTags : [String] = []
    
    var discoverTribesTableViewDataSource : DiscoverTribeTableViewDataSource? = nil
    var rootViewController: RootViewController!
    var delegate: DiscoverTribesWVVCDelegate? = nil
    
    static func instantiate(
        rootViewController: RootViewController
    ) -> DiscoverTribesWebViewController {
        let viewController = StoryboardScene.Welcome.discoverTribesWebViewController.instantiate()
        viewController.rootViewController = rootViewController
        
        return viewController
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        configTableView()
        setupHeaderViews()
        
        
    }
    
    internal func setupHeaderViews() {
        searchTextField.delegate = self
        searchBarContainer.addShadow(
            location: VerticalLocation.bottom,
            opacity: 0.15,
            radius: 3.0
        )
        searchBar.layer.cornerRadius = searchBar.frame.height / 2
        tagsButton.layer.cornerRadius = 14.0
        updateTagButton()
    }
    
    
    func configTableView(){
        discoverTribesTableViewDataSource = DiscoverTribeTableViewDataSource(tableView: tableView, vc: self)
        
        if let dataSource = discoverTribesTableViewDataSource{
            tableView.delegate = dataSource
            tableView.dataSource = dataSource
            dataSource.fetchTribeData(shouldAppend: true)
        }
    }
    
    @IBAction func backButtonTapped(_ sender: Any) {
        if let appDelegate = UIApplication.shared.delegate as? AppDelegate{
            appDelegate.setInitialVC(launchingApp: false, deepLink: true)
        }
    }
    
    @IBAction func tagsButtonTap(_ sender: Any) {
        showTagsFilterView()
    }
    
    
    func showTagsFilterView(){
        let discoverVC = DiscoverTribesTagSelectionVC.instantiate(
                        rootViewController: self.rootViewController
        )
        discoverVC.modalPresentationStyle = .automatic
        discoverVC.discoverTribeTagSelectionVM.selectedTags = currentTags
        self.navigationController?.present(discoverVC, animated: true)
        discoverVC.delegate = self
    }
}

extension DiscoverTribesWebViewController : DiscoverTribesCellDelegate{
    func handleJoin(url: URL) {
        processLink(url: url)
    }
    
    func processLink(url:URL){
        if DeepLinksHandlerHelper.storeLinkQueryFrom(url: url),
           let appDelegate = UIApplication.shared.delegate as? AppDelegate{
            appDelegate.setInitialVC(launchingApp: false, deepLink: true)
        }
    }
}


extension DiscoverTribesWebViewController: UITextFieldDelegate {
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        view.endEditing(true)
        let searchTerm = (searchTextField.text == "") ? nil : searchTextField.text
        discoverTribesTableViewDataSource?.performSearch(searchTerm: searchTerm)
        return true
    }
}

extension DiscoverTribesWebViewController : DiscoverTribesTagSelectionDelegate{
    func didSelect(selections: [String]) {
        let newSet = Set(selections)
        let oldSet = Set(currentTags)
        if(newSet != oldSet){
            self.currentTags = selections
            self.updateTagButton()
            if let dataSource = discoverTribesTableViewDataSource{
                dataSource.fetchTribeData(tags: currentTags, shouldAppend: false)
            }
        }
    }
    
    func updateTagButton(){
        self.tagsButton.backgroundColor = (currentTags.count == 0) ? UIColor.Sphinx.ReceivedMsgBG : UIColor.Sphinx.BodyInverted
        let titleColor = (currentTags.count == 0) ? UIColor.Sphinx.BodyInverted : UIColor.Sphinx.Body
        self.tagsButton.tintColor = titleColor
        self.tagsButton.titleLabel?.textColor = titleColor
        self.tagsButton.titleEdgeInsets = UIEdgeInsets(top: 10,left: 80,bottom: 10,right: 10)
        tagCountContainerView.isHidden = currentTags.count == 0
        tagCountContainerView.makeCircular()
        tagCountLabel.text = "\(currentTags.count)"
    }
    
}
