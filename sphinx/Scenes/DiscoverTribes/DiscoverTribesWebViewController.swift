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
    let urlString = "https://community.sphinx.chat/t"
    var rootViewController: RootViewController!
    //let urlString = "localhost:5000"
    var delegate: DiscoverTribesWVVCDelegate? = nil
    
    static func instantiate(
        rootViewController: RootViewController
    ) -> DiscoverTribesWebViewController {
        let viewController = StoryboardScene.Welcome.discoverTribesWebViewController.instantiate()
        viewController.rootViewController = rootViewController
        
        return viewController
    }
    
    override func viewDidLoad() {
        loadDiscoverTribes()
    }
    
    func loadDiscoverTribes(){
        if let link = URL(string:urlString){
            let request = URLRequest(url: link)
            webView.load(request)
            self.webView.navigationDelegate = self
        }
    }
}


extension DiscoverTribesWebViewController : WKNavigationDelegate{
    func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
           if navigationAction.navigationType == WKNavigationType.linkActivated {
               print("link")
               print(navigationAction.request.url)
               if let url = navigationAction.request.url{
                   if DeepLinksHandlerHelper.storeLinkQueryFrom(url: url),
                      let appDelegate = UIApplication.shared.delegate as? AppDelegate{
                       appDelegate.setInitialVC(launchingApp: false, deepLink: true)
                   }
               }
               decisionHandler(WKNavigationActionPolicy.cancel)
               return
           }
           print("no link")
           decisionHandler(WKNavigationActionPolicy.allow)
    }
}
