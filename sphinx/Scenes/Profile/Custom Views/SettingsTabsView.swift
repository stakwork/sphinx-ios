//
//  SettingsTabsView.swift
//  sphinx
//
//  Created by Tomas Timinskas on 21/08/2020.
//  Copyright © 2020 Sphinx. All rights reserved.
//

import UIKit

protocol SettingsTabsDelegate: class {
    func didChangeSettingsTab(tag: Int)
}

class SettingsTabsView: CommonTabsView {
    
    weak var delegate: SettingsTabsDelegate?
    
    override func getViewIdentifier() -> String {
        return "SettingsTabsView"
    }
    
    override func setSelected() {
        toggleAll(selectedTag: 0)
    }
    
    func setSelectedTabWith(index: Int) {
        toggleAll(selectedTag: index)
    }
    
    override func setViewBorder() {
        container.layer.borderColor = UIColor.Sphinx.LightDivider.resolvedCGColor(with: self)
        container.layer.borderWidth = 1
        container.clipsToBounds = true
    }
    
    @IBAction func buttonTouched(_ sender: UIButton) {
        toggleAll()
        
        sender.setTitleColor(UIColor.white, for: .normal)
        sender.superview?.backgroundColor = UIColor.Sphinx.PrimaryBlue
        setViewBorder()
        
        delegate?.didChangeSettingsTab(tag: sender.tag)
    }

}
