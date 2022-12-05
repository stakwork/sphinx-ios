//
//  WelcomeCompleteViewController.swift
//  sphinx
//
//  Copyright © 2021 Tomas Timinskas. All rights reserved.
//

import UIKit

class WelcomeCompleteViewController: UIViewController {
    @IBOutlet weak var welcomeTitleLabel: UILabel!
    @IBOutlet weak var welcomeSubtitleLabel: UILabel!
    @IBOutlet weak var continueButton: UIButton!
    @IBOutlet weak var continueButtonContainer: UIView!
    
    private var rootViewController: RootViewController!

    
    static func instantiate(
        rootViewController: RootViewController
    ) -> WelcomeCompleteViewController {
        let viewController = StoryboardScene.Welcome.welcomeCompleteViewController.instantiate()
        
        viewController.rootViewController = rootViewController
        
        return viewController
    }

    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        welcomeTitleLabel.text = "welcome.final.title".localized
        welcomeSubtitleLabel.text = "welcome.final.subtitle".localized
        
        setupButton(
            continueButton,
            in: continueButtonContainer,
            withTitle: "welcome.final.continue".localized
        )
    }
    
    
    @IBAction func continueButtonTapped(_ sender: UIButton) {
        SignupHelper.completeSignup()
        UserDefaults.Keys.lastPinDate.set(Date())
        
        let mainCoordinator = MainCoordinator(rootViewController: self.rootViewController)

        mainCoordinator.presentInitialDrawer()
    }
}



extension WelcomeCompleteViewController {
    
    private func setupButton(
        _ button: UIButton,
        in container: UIView,
        withTitle title: String
    ) {
        container.layer.cornerRadius = container.frame.size.height / 2
        container.clipsToBounds = true
        
        container.addShadow(location: .bottom, opacity: 0.5, radius: 2.0)
        
        button.setTitle(title, for: .normal)
    }
}
