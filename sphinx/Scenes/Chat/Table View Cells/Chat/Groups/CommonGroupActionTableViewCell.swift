//
//  CommonGroupActionTableViewCell.swift
//  sphinx
//
//  Created by Tomas Timinskas on 07/07/2020.
//  Copyright © 2020 Tomas Timinskas. All rights reserved.
//

import UIKit

class CommonGroupActionTableViewCell : UITableViewCell {
    
    @IBOutlet weak var groupLeaveLabelContainer: UIView!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        groupLeaveLabelContainer.layer.cornerRadius = getCornerRadius()
        groupLeaveLabelContainer.layer.borderColor = UIColor.Sphinx.LightDivider.resolvedCGColor(with: self)
        groupLeaveLabelContainer.layer.borderWidth = 1
    }
    
    func getCornerRadius() -> CGFloat {
        return groupLeaveLabelContainer.frame.size.height / 2
    }
}
