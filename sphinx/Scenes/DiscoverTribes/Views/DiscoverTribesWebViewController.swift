//
//  DiscoverTribesWkWebView.swift
//  sphinx
//
//  Created by James Carucci on 1/2/23.
//  Copyright © 2023 sphinx. All rights reserved.
//

import Foundation
import WebKit
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
    @IBOutlet weak var webView: WKWebView!
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var searchBar: UIView!
    @IBOutlet weak var searchTextField: UITextField!
    @IBOutlet weak var searchBarContainer: UIView!
    
    var discoverTribesTableViewDataSource : DiscoverTribeTableViewDataSource? = nil
    let urlString = "https://community.sphinx.chat/t"
    var rootViewController: RootViewController!
    //let urlString = "localhost:5000"
    var delegate: DiscoverTribesWVVCDelegate? = nil
    var shouldUseWebview = false
    
    
    static func instantiate(
        rootViewController: RootViewController
    ) -> DiscoverTribesWebViewController {
        let viewController = StoryboardScene.Welcome.discoverTribesWebViewController.instantiate()
        viewController.rootViewController = rootViewController
        
        return viewController
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.backgroundColor = UIColor.Sphinx.Body
        webView.backgroundColor = UIColor.Sphinx.Body
        self.view.backgroundColor = UIColor.Sphinx.Body
        
        if(shouldUseWebview){
            loadDiscoverTribesWebView()
            searchBar.isHidden = true
            tableView.isHidden = true
        }
        else{
            configTableView()
            webView.isHidden = true
        }
        setupHeaderViews()
    }
    
    func loadDiscoverTribesWebView(){
        if let link = URL(string:urlString){
            let request = URLRequest(url: link)
            webView.load(request)
            self.webView.navigationDelegate = self
        }
    }
    
    internal func setupHeaderViews() {
        searchTextField.delegate = self
        searchBarContainer.addShadow(
            location: VerticalLocation.bottom,
            opacity: 0.15,
            radius: 3.0
        )
        
        searchBar.layer.cornerRadius = searchBar.frame.height / 2
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
        if let appDelegate = UIApplication.shared.delegate as? AppDelegate{
            appDelegate.setInitialVC(launchingApp: false, deepLink: true)
        }
    }
    
    
}


extension DiscoverTribesWebViewController : WKNavigationDelegate{
    func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
           if navigationAction.navigationType == WKNavigationType.linkActivated {
               print("link")
               print(navigationAction.request.url)
               if let url = navigationAction.request.url{
                   processLink(url:url)
               }
               decisionHandler(WKNavigationActionPolicy.cancel)
               return
           }
           print("no link")
           decisionHandler(WKNavigationActionPolicy.allow)
    }
    
    func processLink(url:URL){
        if DeepLinksHandlerHelper.storeLinkQueryFrom(url: url),
           let appDelegate = UIApplication.shared.delegate as? AppDelegate{
            appDelegate.setInitialVC(launchingApp: false, deepLink: true)
        }
    }
}


extension DiscoverTribesWebViewController : DiscoverTribesCellDelegate{
    func handleJoin(url: URL) {
        processLink(url: url)
    }
}


extension DiscoverTribesWebViewController: UITextFieldDelegate {
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        view.endEditing(true)
        let searchTerm = (searchTextField.text == "") ? nil : searchTextField.text
        discoverTribesTableViewDataSource?.fetchTribeData(searchTerm: searchTerm)
        return true
    }
}
