//
//  BadgeDetailVC.swift
//  sphinx
//
//  Created by James Carucci on 12/28/22.
//  Copyright © 2022 sphinx. All rights reserved.
//

import Foundation
import UIKit

public enum BadgeDetailPresentationContext{
    case template
    case existing
}

class BadgeAdminDetailVC : UIViewController{
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
    @IBOutlet weak var stepperPlaceholderView: UIView!
    @IBOutlet weak var stepperMinusButton: UIButton!
    @IBOutlet weak var stepperPlusButton: UIButton!
    @IBOutlet weak var badgeQuantityStepperLabel: UILabel!
    @IBOutlet weak var satsTotalLabel: UILabel!
    @IBOutlet weak var badgeNameLabel: UILabel!
    @IBOutlet weak var totalStaticLabel: UILabel!
    @IBOutlet weak var pricePerBadgeAmountLabel: UILabel!
    @IBOutlet weak var badgeActivationContainerView: UIView!
    @IBOutlet weak var badgeActivateDeactivateLabel: UILabel!
    @IBOutlet weak var badgeActivateDeactivateSwitch: UISwitch!
    @IBOutlet weak var badgeActivationContainerHeight: NSLayoutConstraint!
    @IBOutlet weak var createBadgeImage: UIImageView!
    
    
    @IBOutlet weak var badgeStatsLabel: UILabel!
    @IBOutlet weak var badgeStatsLabelHeight: NSLayoutConstraint!
    @IBOutlet weak var badgeStatsLabelBottomConstraint: NSLayoutConstraint!
    @IBOutlet weak var badgeStatsLabelTopConstraint: NSLayoutConstraint!
    
    var presentationContext : BadgeDetailPresentationContext = .template
    var associatedBadge : Badge? = nil
    let pricePerBadge : Int = 10
    var badgeQuantity : Int = 100 {
        didSet{
            print("Value is now \(badgeQuantity)")
            updateBadgeQuantities()
        }
    }
    
    
    override func viewDidLoad() {
        //changeIconView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(handleChangeIcon)))
        vcScrollView.isScrollEnabled = true
        vcScrollView.contentSize = CGSize(width: self.view.frame.width, height: 900.0)
        if let valid_badge = associatedBadge{
            loadWithBadge(badge: valid_badge)
        }
        styleSubViews()
       customizeBasedOnPresentationContext()
        
        disableEditing()
    }
    
    func disableEditing(){
        //changeIconView.isHidden = true
        //badgeNameTextField.isUserInteractionEnabled = false
        
    }
    
    func customizeBasedOnPresentationContext(){
        switch(presentationContext){
        case .existing:
            saveBadgeButton.isHidden = true
            quantityLabel.isHidden = true
            stepperPlaceholderView.isHidden = true
            pricePerBadgeLabel.isHidden = true
            satsTotalLabel.isHidden = true
            pricePerBadgeAmountLabel.isHidden = true
            totalStaticLabel.isHidden = true
            createBadgeImage.isHidden = true
            if let valid_badge = associatedBadge,
               let badgesCreated = valid_badge.amount_created,
               let badgesIssued = valid_badge.amount_issued{
                let remainingAmountText = String(max(0, badgesCreated - badgesIssued))
                let fullText = "\(remainingAmountText) of \(badgesCreated) left"
                let attributedString = NSMutableAttributedString(string: fullText)
                attributedString.addAttribute(.foregroundColor, value: UIColor.Sphinx.BodyInverted, range: NSRange(location: 0, length: remainingAmountText.count))
                
                badgeStatsLabel.attributedText = attributedString
                
                badgeActivateDeactivateLabel.text = (valid_badge.activationState == true) ? "Deactivate Badge" : "Activate Badge"
                badgeActivateDeactivateSwitch.isOn = valid_badge.activationState
            }
            vcScrollView.contentSize = CGSize(width: self.view.frame.width, height: 400.0)
            break
        case .template:
            saveBadgeButton.setTitle("Purchase Badges", for: .normal)
            badgeActivationContainerView.isHidden = true
            badgeActivationContainerHeight.constant = 0
            badgeStatsLabelHeight.constant = 0
            badgeStatsLabelTopConstraint.constant = 0
            badgeStatsLabelBottomConstraint.constant = 0
            //saveBadgeButton.setTitle("Update Badge", for: .normal)
            vcScrollView.contentSize = CGSize(width: self.view.frame.width, height: 650.0)
            print(vcScrollView.contentSize.height)
            break
        }
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
        stepperMinusButton.setTitle("", for: .normal)
        stepperPlusButton.setTitle("", for: .normal)
        stepperMinusButton.backgroundColor = UIColor.Sphinx.LightBG
        stepperPlusButton.backgroundColor = UIColor.Sphinx.LightBG
        stepperPlaceholderView.backgroundColor = UIColor.Sphinx.DashboardSearch
        stepperPlaceholderView.layer.cornerRadius = 16.0
        stepperMinusButton.layer.cornerRadius = stepperMinusButton.layer.bounds.width / 2
        stepperPlusButton.layer.cornerRadius = stepperMinusButton.layer.bounds.width / 2
        //requirementLabel.textColor = UIColor.Sphinx.SecondaryText
       // badgeTitleLabel.textColor = UIColor.Sphinx.SecondaryText
        quantityLabel.textColor = UIColor.Sphinx.SecondaryText
        pricePerBadgeLabel.textColor = UIColor.Sphinx.SecondaryText
        //iconRequirementsLabel.textColor = UIColor.Sphinx.SecondaryText
        //changeIconView.layer.cornerRadius = 20
        //changeIconView.layer.borderWidth = 1
        //changeIconView.layer.borderColor = UIColor.Sphinx.BubbleShadow.cgColor
        //badgeImageView.addLineDashedStroke(pattern: [2, 2], radius: 0, color: UIColor.gray.cgColor)
        saveBadgeButton.layer.cornerRadius = saveBadgeButton.frame.height/2.0
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
    
    func updateBadgeQuantities(){
        let numberFormatter = NumberFormatter()
        numberFormatter.numberStyle = .decimal
        if let formattedQuantity = numberFormatter.string(from: NSNumber(value:badgeQuantity)),
        let formattedTotal = numberFormatter.string(from: NSNumber(value:badgeQuantity * pricePerBadge)){
            badgeQuantityStepperLabel.text = "\(String(describing: formattedQuantity))"
            satsTotalLabel.text = "\(String(describing: formattedTotal)) sats"
        }
        
    }
    
    func loadWithBadge(badge:Badge){
        if let valid_icon = badge.icon_url{
            let bitmapSize = CGSize(width: 500, height: 500)
            badgeImageView.sd_setImage(with: URL(string: valid_icon), placeholderImage: nil, options: [], context: [.imageThumbnailPixelSize : bitmapSize])
        }
        //badgeNameTextField.text = badge.name ?? ""
        viewTitle.text = badge.name ?? ""
        badgeNameLabel.text = badge.name ?? ""
        badgeRequirementDescriptionLabel.text = badge.requirements ?? ""
        
    }
    
    
    @IBAction func plusMinusButtonTouch(_ sender: Any) {
        let maxValue = 200
        let minValue = 0
        if let buttonSender = sender as? UIButton{
            var incrementValue = 0
            if buttonSender == stepperPlusButton{
                print("plus")
                incrementValue = 1
            }
            else if buttonSender == stepperMinusButton{
                print("minus")
                incrementValue = -1
            }
            badgeQuantity += incrementValue
            badgeQuantity = (badgeQuantity >= maxValue) ? maxValue : badgeQuantity
            badgeQuantity = (badgeQuantity <= minValue) ? minValue : badgeQuantity
            UIButton.animate(withDuration: 0.05, animations: {
                let alphaChange = 0.5
                buttonSender.alpha -= alphaChange
                buttonSender.alpha += alphaChange
            })
        }
        
    }
    
    
    
    
}

extension BadgeAdminDetailVC : AttachmentsDelegate{
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
