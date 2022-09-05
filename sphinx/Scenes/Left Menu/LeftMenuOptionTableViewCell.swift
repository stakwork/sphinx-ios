//
//  LeftMenuOptionTableViewCell.swift
//  sphinx
//
//  Created by Tomas Timinskas on 20/09/2019.
//  Copyright © 2019 Sphinx. All rights reserved.
//

import UIKit

class LeftMenuOptionTableViewCell: UITableViewCell {
    
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var iconLabel: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
    }
    
    func configureCell(option: LeftMenuViewController.MenuOption) {
        iconLabel.text = option.iconCharacter
        titleLabel.text = option.optionTitle
    }
}
