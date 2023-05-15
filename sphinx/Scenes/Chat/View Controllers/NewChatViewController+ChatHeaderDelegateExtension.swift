//
//  NewChatViewController+ChatHeaderDelegateExtension.swift
//  sphinx
//
//  Created by Tomas Timinskas on 15/05/2023.
//  Copyright © 2023 sphinx. All rights reserved.
//

import UIKit

extension NewChatViewController : ChatHeaderViewDelegate {
    func didTapHeaderButton() {
        
    }
    
    func didTapBackButton() {
        self.navigationController?.popViewController(animated: true)
    }
    
    func didTapWebAppButton() {
        
    }
    
    func didTapMuteButton() {
        
    }
    
    func didTapMoreOptionsButton(sender: UIButton) {
        
    }
    
}
