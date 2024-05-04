//
//  NewChatViewController+WebAppExtension.swift
//  sphinx
//
//  Created by Tomas Timinskas on 30/05/2023.
//  Copyright © 2023 sphinx. All rights reserved.
//

import UIKit

extension NewChatViewController {
    func toggleWebAppContainer(isAppURL: Bool = true) {
        let shouldShow = webAppContainerView.isHidden
        
        if shouldShow {
            if let chat = chat {
                if webAppVC == nil || self.isAppUrl != isAppURL {
                    if let webAppVC = WebAppViewController.instantiate(chat: chat, isAppURL: isAppURL) {
                        self.webAppVC = webAppVC
                    }
                }
                if let webAppVC = webAppVC {
                    addChildVC(child: webAppVC, container: webAppContainerView)
                }
            }
        } else if let webAppVC = webAppVC {
            removeChildVC(child: webAppVC)
        }
        
        self.isAppUrl = isAppURL
        bottomView.isHidden = shouldShow
        webAppContainerView.isHidden = !webAppContainerView.isHidden
        
        if isAppURL {
            headerView.toggleWebAppIcon(showChatIcon: shouldShow)
        } else {
            headerView.toggleSBIcon(showChatIcon: shouldShow)
        }
    }
}
