//
//  SphinxDesktopAdViewController.swift
//  sphinx
//
//  Copyright © 2021 sphinx. All rights reserved.
//

import UIKit


class SphinxDesktopAdViewController: UIViewController {
    @IBOutlet weak var headlineLabel: UILabel!
    @IBOutlet weak var getItNowButtonView: UIButton!
    @IBOutlet weak var skipButtonView: UIButton!
    
    static let desktopAppStoreURL = URL(string: "https://sphinx.chat/")!
    
    static func instantiate() -> SphinxDesktopAdViewController {
        let viewController = StoryboardScene.NewUserSignup.sphinxDesktopAdViewController.instantiate()
        return viewController
    }

    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupHeadlineLabel()
        setupButtons()
    }
    
    
    @IBAction func getItNowButtonTapped(_ sender: UIButton) {
        UIApplication.shared.open(Self.desktopAppStoreURL)
    }
    
    
    @IBAction func skipButtonTapped(_ sender: UIButton) {
        let sphinxReadyVC = SphinxReadyViewController.instantiate()
        navigationController?.pushViewController(sphinxReadyVC, animated: true)
    }
}


extension SphinxDesktopAdViewController {
    
    private func setupButtons() {
        [getItNowButtonView!, skipButtonView!].forEach { button in
            button.layer.cornerRadius = button.frame.size.height / 2
            button.clipsToBounds = true
            button.addShadow(location: .bottom, opacity: 0.2, radius: 2.0)
        }

        getItNowButtonView.layer.borderWidth = 1
        getItNowButtonView.layer.borderColor = UIColor.white.cgColor
        getItNowButtonView.setTitle(
            "signup.desktop-ad.get-now".localized,
            for: .normal
        )
        
        skipButtonView.setTitle(
            "signup.desktop-ad.skip".localized,
            for: .normal
        )
        skipButtonView.accessibilityIdentifier = "skipButtonView"
    }
    
    
    private func setupHeadlineLabel() {
        let labelText = "signup.desktop-ad.headline".localized
        let boldLabels = ["signup.desktop-ad.sphinx-on-desktop".localized]
        
        let normalFont = UIFont(name: "Roboto-Light", size: 30.0)!
        let boldFont = UIFont(name: "Roboto-Bold", size: 30.0)!
        
        
        headlineLabel.attributedText =  String.getAttributedText(
            string: labelText,
            boldStrings: boldLabels,
            font: normalFont,
            boldFont: boldFont
        )
    }
}
