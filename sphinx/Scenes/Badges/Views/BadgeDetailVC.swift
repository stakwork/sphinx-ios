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
    @IBOutlet weak var badgeRequirementDescriptionLabel: UILabel!
    @IBOutlet weak var saveBadgeButton: UIButton!
    @IBOutlet weak var iconRequirementsLabel: UILabel!
    @IBOutlet weak var requirementLabel: UILabel!
    @IBOutlet weak var badgeTitleLabel: UILabel!
    @IBOutlet weak var quantityLabel: UILabel!
    @IBOutlet weak var pricePerBadgeLabel: UILabel!
    
    var associatedBadge : Badge? = nil
    
    
    override func viewDidLoad() {
        changeIconView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(handleChangeIcon)))
        vcScrollView.isScrollEnabled = true
        vcScrollView.contentSize = CGSize(width: self.view.frame.width, height: 900.0)
        if let valid_badge = associatedBadge{
            loadWithBadge(badge: valid_badge)
        }
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
        requirementLabel.textColor = UIColor.Sphinx.SecondaryText
        badgeTitleLabel.textColor = UIColor.Sphinx.SecondaryText
        quantityLabel.textColor = UIColor.Sphinx.SecondaryText
        pricePerBadgeLabel.textColor = UIColor.Sphinx.SecondaryText
        iconRequirementsLabel.textColor = UIColor.Sphinx.SecondaryText
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
        if AttachmentsManager.sharedInstance.uploading || self.presentedViewController != nil {
            return
        }
        
        let viewController = ChatAttachmentViewController.instantiate(delegate: self, chat: nil)
        viewController.presentationContext = .fromBadgeCreateUpdate
        viewController.modalPresentationStyle = .overCurrentContext
        self.present(viewController, animated: false)
    }
    
    
    @IBAction func createBadgeButtonTap(_ sender: Any) {
        //Call API
    }
    
    func loadWithBadge(badge:Badge){
        if let valid_icon = badge.icon_url{
            badgeImageView.sd_setImage(with: URL(string: valid_icon))
        }
        badgeNameTextField.text = badge.name ?? ""
        badgeRequirementDescriptionLabel.text = badge.requirements ?? ""
        
    }
    
    
}

extension BadgeDetailVC : AttachmentsDelegate{
    func willDismissPresentedVC() {
        
    }
    
    func shouldStartUploading(attachmentObject: AttachmentObject) {
        badgeImageView.image = attachmentObject.image
    }
    
    func shouldSendGiphy(message: String) {
        
    }
    
    func didCloseReplyView() {
        
    }
    
    func didTapSendButton() {
        
    }
    
    func didTapReceiveButton() {
        
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
