//
//  MaxContentAgeTableViewCell.swift
//  sphinx
//
//  Created by James Carucci on 7/5/23.
//  Copyright © 2023 sphinx. All rights reserved.
//

import UIKit

class MaxContentAgeTableViewCell: UITableViewCell {

    @IBOutlet weak var selectedDeselectedImageView: UIImageView!
    @IBOutlet weak var durationLabel: UILabel!
    @IBOutlet weak var customAgeTextField: UITextField!
    @IBOutlet weak var daysLabel: UILabel!
    
    static let reuseID = "MaxContentAgeTableViewCell"
    var isSelectedRow: Bool = false{
        didSet{
            selectedDeselectedImageView.image = (isSelectedRow) ? #imageLiteral(resourceName: "selected-radio-button") : #imageLiteral(resourceName: "unselected-radio-button")
            selectedDeselectedImageView.tintColor = (isSelectedRow) ? UIColor.Sphinx.PrimaryBlue : UIColor.Sphinx.PlaceholderText
        }
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
    override func prepareForReuse() {
        self.isSelectedRow = false
        durationLabel.isHidden = false
        customAgeTextField.isHidden = true
        daysLabel.isHidden = customAgeTextField.isHidden
    }
    
    func configureWithDuration(age:MessageAgePossibilities){
        switch(age){
        case .customDays:
            durationLabel.isHidden = true
            customAgeTextField.isHidden = false
            customAgeTextField.text = String(UserData.sharedInstance.getCustomMaxAgeValueInDays())
            break
        default:
            durationLabel.isHidden = false
            durationLabel.text = age.localizedDescription
            customAgeTextField.isHidden = true
            break
        }
        daysLabel.isHidden = customAgeTextField.isHidden
    }
}
