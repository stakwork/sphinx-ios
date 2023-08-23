//
//  AppSizeView.swift
//  sphinx
//
//  Created by Tomas Timinskas on 31/07/2020.
//  Copyright © 2020 Sphinx. All rights reserved.
//

import UIKit

class AppSizeView: CommonTabsView {
    
    override func getViewIdentifier() -> String {
        return "AppSizeView"
    }
    
    override func setSelected() {
        let size = UserDefaults.Keys.messagesSize.get(defaultValue: MessagesSize.Big.rawValue)
        toggleAll(selectedTag: size)
    }
    
    @IBAction func buttonTouched(_ sender: UIButton) {
        toggleAll()
        
        sender.setTitleColor(UIColor.white, for: .normal)
        sender.superview?.backgroundColor = UIColor.Sphinx.PrimaryBlue
        
        UserDefaults.Keys.messagesSize.set(sender.tag)
        Constants.setSize()
        setViewBorder()
        
        NotificationCenter.default.post(name: .onSizeConfigurationChanged, object: nil)
    }
}
