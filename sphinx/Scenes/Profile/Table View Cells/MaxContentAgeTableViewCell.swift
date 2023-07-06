//
//  MaxContentAgeTableViewCell.swift
//  sphinx
//
//  Created by James Carucci on 7/5/23.
//  Copyright © 2023 sphinx. All rights reserved.
//

import UIKit

protocol MaxContentAgeTableViewCellDelegate{
    func didChangeCustomLength(value:Int)
}

class MaxContentAgeTableViewCell: UITableViewCell {

    @IBOutlet weak var selectedDeselectedImageView: UIImageView!
    @IBOutlet weak var durationLabel: UILabel!
    @IBOutlet weak var customAgeTextField: UITextField!
    @IBOutlet weak var daysLabel: UILabel!
    @IBOutlet weak var customAgeContainerView: UIView!
    
    var delegate : MaxContentAgeTableViewCellDelegate? = nil
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
        customAgeContainerView.isHidden = true
        daysLabel.isHidden = customAgeTextField.isHidden
    }
    
    func configureWithDuration(age:MessageAgePossibilities){
        switch(age){
        case .customDays:
            durationLabel.isHidden = true
            customAgeContainerView.isHidden = false
            customAgeTextField.text = String(UserData.sharedInstance.getCustomMaxAgeValueInDays())
            break
        default:
            durationLabel.isHidden = false
            durationLabel.text = age.localizedDescription
            customAgeContainerView.isHidden = true
            break
        }
        daysLabel.isHidden = customAgeContainerView.isHidden
        setupTextField()
    }
    
    func setupTextField(){
        customAgeTextField.delegate = self
        customAgeTextField.font = UIFont(name: "Roboto", size: 17.0)
        customAgeContainerView.layer.cornerRadius = customAgeTextField.frame.height/2.0
        
          if #available(iOS 13.0, *) {
              if UIScreen.main.traitCollection.userInterfaceStyle == .dark {
                  // Dark mode is active
                  print("Dark mode")
                  customAgeContainerView.backgroundColor = UIColor(hex: "#131B1D")
              } else {
                  // Light mode is active
                  print("Light mode")
                  customAgeContainerView.backgroundColor = UIColor(hex: "#CECECE")
              }
          } else {
              customAgeContainerView.backgroundColor = UIColor(hex: "#CECECE")
          }
    }
}

extension MaxContentAgeTableViewCell : UITextFieldDelegate{
    func textFieldDidEndEditing(_ textField: UITextField) {
        if let text = textField.text,
           let intValue = Int(text){
            delegate?.didChangeCustomLength(value: intValue)
        }
//        else{
//            textField.text = textField.text?.remove(at: textField.text?.count)
//        }
    }
}
