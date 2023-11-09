//
//  NewUserSignupDescriptionViewController.swift
//  sphinx
//
//  Copyright © 2021 sphinx. All rights reserved.
//

import UIKit

class NewUserSignupDescriptionViewController: UIViewController {

    @IBOutlet weak var imageSubtitle: UILabel!
    @IBOutlet weak var continueButtonContainer: UIView!
    @IBOutlet weak var continueButton: UIButton!

    
    static func instantiate() -> NewUserSignupDescriptionViewController {
        let viewController = StoryboardScene.NewUserSignup.newUserSignupDescriptionViewController.instantiate()
        return viewController
    }

    
    override func viewDidLoad() {
        super.viewDidLoad()

        setupContinueButton()
        setAttributedTextSubtitle()
        addAccessibilityIdentifiers()
    }
    
    func addAccessibilityIdentifiers(){
        continueButton.accessibilityIdentifier = "signup.description.continue"
    }
    
    
    @IBAction func continueButtonTapped(_ sender: UIButton) {
        let newUserSignupFormVC = NewUserSignupFormViewController.instantiate()
        self.navigationController?.pushViewController(newUserSignupFormVC, animated: true)
    }
}


extension NewUserSignupDescriptionViewController {
 
    private func setupContinueButton() {
        continueButton.layer.cornerRadius = continueButton.frame.size.height / 2
        continueButton.clipsToBounds = true
        continueButton.addShadow(location: .bottom, opacity: 0.12, radius: 2.0)
        continueButton.setTitle(
            "signup.description.continue".localized,
            for: .normal
        )
    }
    
    
    private func setAttributedTextSubtitle() {
        let labelText = "signup.description.label".localized
        let boldLabels = [
            "signup.description.paste".localized,
            "signup.description.connection-code".localized,
        ]
        
        let normalFont = UIFont(name: "Roboto-Light", size: 15.0)!
        let boldFont = UIFont(name: "Roboto-Bold", size: 15.0)!
        
        
        imageSubtitle.attributedText =  String.getAttributedText(
            string: labelText,
            boldStrings: boldLabels,
            font: normalFont,
            boldFont: boldFont
        )
        imageSubtitle.accessibilityIdentifier = "signup.description.label"
    }
}
