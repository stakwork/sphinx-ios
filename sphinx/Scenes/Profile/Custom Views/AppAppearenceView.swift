//
//  AppAppearenceView.swift
//  sphinx
//
//  Created by Tomas Timinskas on 23/06/2020.
//  Copyright © 2020 Sphinx. All rights reserved.
//

import UIKit

protocol AppearenceViewDelegate: class {
    func didChangeAppearance()
}

class AppAppearenceView: CommonTabsView {
    
    weak var delegate: AppearenceViewDelegate?
    
    override func getViewIdentifier() -> String {
        return "AppAppearenceView"
    }
    
    override func setSelected() {
        let style = UserDefaults.Keys.appAppearence.get(defaultValue: UIWindow.Style.System.rawValue)
        toggleAll(selectedTag: style)
    }
    
    @IBAction func buttonTouched(_ sender: UIButton) {
        toggleAll()
        
        sender.setTitleColor(UIColor.white, for: .normal)
        sender.superview?.backgroundColor = UIColor.Sphinx.PrimaryBlue
        
        UserDefaults.Keys.appAppearence.set(sender.tag)
        window?.setStyle()
        
        setViewBorder()
        
        delegate?.didChangeAppearance()
    }
}
