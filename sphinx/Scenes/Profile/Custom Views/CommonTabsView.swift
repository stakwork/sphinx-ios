//
//  CommonTabsView.swift
//  sphinx
//
//  Created by Tomas Timinskas on 21/08/2020.
//  Copyright © 2020 Sphinx. All rights reserved.
//

import UIKit

class CommonTabsView : UIView {
    
    @IBOutlet var contentView: UIView!
    @IBOutlet weak var container: UIView!
    @IBOutlet var buttonViews: [UIView]!
    @IBOutlet var buttons: [UIButton]!
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setup()
    }
    
    private func setup() {
        Bundle.main.loadNibNamed(getViewIdentifier(), owner: self, options: nil)
        addSubview(contentView)
        contentView.frame = self.bounds
        contentView.autoresizingMask = [.flexibleHeight, .flexibleWidth]
        
        setViewBorder()
        setSelected()
    }
    
    func getViewIdentifier() -> String {
        return ""
    }
    
    func setViewBorder() {
        container.layer.cornerRadius = container.frame.height / 2
        container.layer.borderColor = UIColor.Sphinx.LightDivider.resolvedCGColor(with: self)
        container.layer.borderWidth = 1
        container.clipsToBounds = true
    }
    
    func setSelected() { }
    
    func toggleAll(selectedTag: Int = -1) {
        for view in buttonViews {
            if view.tag == selectedTag {
                view.backgroundColor = UIColor.Sphinx.PrimaryBlue
            } else {
                view.backgroundColor = UIColor.Sphinx.Body
            }
        }
        
        for button in buttons {
            if button.tag == selectedTag {
                button.setTitleColor(UIColor.white, for: .normal)
            } else {
                button.setTitleColor(UIColor.Sphinx.Text, for: .normal)
            }
        }
    }
}
