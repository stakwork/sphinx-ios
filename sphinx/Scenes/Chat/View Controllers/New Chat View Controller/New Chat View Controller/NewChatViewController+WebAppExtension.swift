//
//  NewChatViewController+WebAppExtension.swift
//  sphinx
//
//  Created by Tomas Timinskas on 30/05/2023.
//  Copyright © 2023 sphinx. All rights reserved.
//

import UIKit

extension NewChatViewController {
    func toggleWebAppContainer() {
        let shouldShow = webAppContainerView.isHidden
        
        if shouldShow {
            if let chat = chat, webAppVC == nil {
                webAppVC = WebAppViewController.instantiate(chat: chat)
            }
            addChildVC(child: webAppVC!, container: webAppContainerView)
        } else if let webAppVC = webAppVC {
            removeChildVC(child: webAppVC)
        }
        
        bottomView.isHidden = shouldShow
        webAppContainerView.isHidden = !webAppContainerView.isHidden
        
        headerView.toggleWebAppIcon(showChatIcon: shouldShow)
    }
}
