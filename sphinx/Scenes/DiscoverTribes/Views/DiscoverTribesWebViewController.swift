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
    @IBOutlet weak var filterIcon: UILabel!
    @IBOutlet weak var discoverTribesTitle: UILabel!
    
    
    var currentTags : [String] = []
    
    var discoverTribesTableViewDataSource : DiscoverTribeTableViewDataSource? = nil
    var delegate: DiscoverTribesWVVCDelegate? = nil
    
    static func instantiate() -> DiscoverTribesWebViewController {
        let viewController = StoryboardScene.Welcome.discoverTribesWebViewController.instantiate()
        return viewController
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.accessibilityIdentifier = "DiscoverTribesWebViewController"
        configTableView()
        setupHeaderViews()
    }
    
    
    internal func setupHeaderViews() {
        searchTextField.delegate = self
        
        tagCountContainerView.makeCircular()
        searchBar.makeCircular()
        tagsButton.makeCircular()
        
        updateTagButton()
    }
    
    
    func configTableView(){
        discoverTribesTableViewDataSource = DiscoverTribeTableViewDataSource(tableView: tableView, vc: self)
        
        if let dataSource = discoverTribesTableViewDataSource{
            tableView.delegate = dataSource
            tableView.dataSource = dataSource
            dataSource.fetchTribeData()
        }
    }
    
    @IBAction func backButtonTapped(_ sender: Any) {
        navigationController?.popViewController(animated: true)
    }
    
    @IBAction func tagsButtonTap(_ sender: Any) {
        showTagsFilterView()
    }
    
    
    func showTagsFilterView(){
        let discoverVC = DiscoverTribesTagSelectionVC.instantiate()
        discoverVC.modalPresentationStyle = .overCurrentContext
        self.navigationController?.present(discoverVC, animated: false)
        
        discoverVC.discoverTribeTagSelectionVM.selectedTags = currentTags
        discoverVC.delegate = self
    }
}

extension DiscoverTribesWebViewController : DiscoverTribesCellDelegate {
    func handleJoin(url: URL) {
        processLink(url: url)
    }
    
    func processLink(url:URL) {
        if DeepLinksHandlerHelper.storeLinkQueryFrom(url: url) {
            navigationController?.popViewController(animated: true)
        }
    }
}


extension DiscoverTribesWebViewController: UITextFieldDelegate {
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        
        view.endEditing(true)
        
        let searchTerm = (searchTextField.text == "") ? nil : searchTextField.text
        
        discoverTribesTableViewDataSource?.performSearch(
            searchTerm: searchTerm,
            tags: currentTags
        )
        
        return true
    }
}

extension DiscoverTribesWebViewController : DiscoverTribesTagSelectionDelegate {
    func didSelect(selections: [String]) {
        
        let newSet = Set(selections)
        let oldSet = Set(currentTags)
        
        if (newSet != oldSet) {
            
            self.currentTags = selections
            self.updateTagButton()
            
            if let dataSource = discoverTribesTableViewDataSource {
                let searchTerm = (searchTextField.text == "") ? nil : searchTextField.text
                dataSource.applyTags(searchTerm: searchTerm, tags: self.currentTags)
            }
        }
    }
    
    func updateTagButton() {
        let tagsSelected = (currentTags.count > 0)
        
        filterIcon.isHidden = tagsSelected
        tagsButton.backgroundColor = tagsSelected ? UIColor.Sphinx.BodyInverted : UIColor.Sphinx.ReceivedMsgBG
        tagsButton.tintColor = tagsSelected ? UIColor.Sphinx.TextInverted : UIColor.Sphinx.Text
        tagsButton.setTitleColor(tagsSelected ? UIColor.Sphinx.TextInverted : UIColor.Sphinx.Text, for: .normal)
        
        tagCountContainerView.isHidden = !tagsSelected
        tagCountLabel.text = "\(currentTags.count)"
    }
    
}
