//
//  BadgeDetailVC.swift
//  sphinx
//
//  Created by James Carucci on 12/28/22.
//  Copyright © 2022 sphinx. All rights reserved.
//

import Foundation
import UIKit

class BadgeDetailVC : UIViewController{
    @IBOutlet weak var navBarView: UIView!
    @IBOutlet weak var badgeImageView: UIImageView!
    @IBOutlet weak var viewTitle: UILabel!
    @IBOutlet weak var changeIconView: UIView!
    @IBOutlet weak var badgeNameTextField: UITextField!
    @IBOutlet weak var vcScrollView: UIScrollView!
    @IBOutlet weak var saveBadgeButton: UIButton!
    
    
    override func viewDidLoad() {
        changeIconView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(handleChangeIcon)))
        vcScrollView.isScrollEnabled = true
        vcScrollView.contentSize = CGSize(width: self.view.frame.width, height: 1000.0)
        styleSubViews()
    }
    
    static func instantiate(
        rootViewController: RootViewController
    ) -> UIViewController {
        let viewController = StoryboardScene.BadgeManagement.badgeDetailViewController.instantiate()
        //viewController.rootViewController = rootViewController
        
        return viewController
    }
    
    func styleSubViews(){
        view.backgroundColor = UIColor.Sphinx.Body
        changeIconView.layer.cornerRadius = 20
        changeIconView.layer.borderWidth = 1
        changeIconView.layer.borderColor = UIColor.Sphinx.BubbleShadow.cgColor
        badgeImageView.addLineDashedStroke(pattern: [2, 2], radius: 0, color: UIColor.gray.cgColor)
        saveBadgeButton.layer.cornerRadius = 36.0
        saveBadgeButton.backgroundColor = UIColor.Sphinx.PrimaryGreen
        saveBadgeButton.tintColor = .clear
    }
    
    @IBAction func backButtonPressed(_ sender: Any) {
        self.navigationController?.popViewController(animated: true)

    }
    
    @objc func handleChangeIcon(){
        print("Changing icon")
    }
    
}

extension UIView {
    @discardableResult
    func addLineDashedStroke(pattern: [NSNumber]?, radius: CGFloat, color: CGColor) -> CALayer {
        let borderLayer = CAShapeLayer()

        borderLayer.strokeColor = color
        borderLayer.lineDashPattern = pattern
        borderLayer.frame = bounds
        borderLayer.fillColor = nil
        borderLayer.path = UIBezierPath(roundedRect: bounds, byRoundingCorners: .allCorners, cornerRadii: CGSize(width: radius, height: radius)).cgPath

        layer.addSublayer(borderLayer)
        return borderLayer
    }
}
