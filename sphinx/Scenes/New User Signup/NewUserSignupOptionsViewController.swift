//
//  NewUserSignupOptionsViewController.swift
//  sphinx
//
//  Created by Brian Sipple on 7/1/21.
//  Copyright © 2021 sphinx. All rights reserved.
//

import UIKit

class NewUserSignupOptionsViewController: UIViewController {
    @IBOutlet weak var screenHeadlineLabel: UILabel!
    @IBOutlet weak var connectionCodeButtonContainer: UIView!
    @IBOutlet weak var connectionCodeButton: UIButton!
    @IBOutlet weak var purchaseLiteNodeButtonContainer: UIView!
    @IBOutlet weak var purchaseLiteNodeButton: UIButton!
    
    
    private var rootViewController: RootViewController!

    
    static func instantiate(
        rootViewController: RootViewController
    ) -> NewUserSignupOptionsViewController {
        let viewController = StoryboardScene.NewUserSignup.newUserSignupOptionsViewController.instantiate()
        
        viewController.rootViewController = rootViewController
        
        return viewController
    }

    
    override func viewDidLoad() {
        super.viewDidLoad()

        setupButton(
            connectionCodeButton,
            withTitle: "signup.signup-options.connection-code-button".localized,
            andBackgroundColor: UIColor.Sphinx.PrimaryBlue
        )
        
        setupButton(
            purchaseLiteNodeButton,
            withTitle: "signup.signup-options.lite-node-button".localized,
            andBackgroundColor: UIColor.Sphinx.PrimaryGreen
        )
    }
    
    
    @IBAction func connectionCodeButtonTapped(_ sender: UIButton) {
        let nextVC = NewUserSignupDescriptionViewController.instantiate(
            rootViewController: rootViewController
        )
        
        navigationController?.pushViewController(nextVC, animated: true)
    }
    
    
    @IBAction func purchaseLiteNodeButtonTapped(_ sender: UIButton) {
        // TODO: Present some view for making an In-App Purchase Here
    }
}


extension NewUserSignupOptionsViewController {
 
    private func setupButton(
        _ button: UIButton,
        withTitle title: String,
        andBackgroundColor backgroundColor: UIColor
    ) {
        
        button.setTitle(title, for: .normal)
        button.layer.cornerRadius = button.frame.size.height / 2
        button.clipsToBounds = true
        
        button.addShadow(location: .bottom, color: backgroundColor, opacity: 0.2, radius: 2.0)
    }
}
    
