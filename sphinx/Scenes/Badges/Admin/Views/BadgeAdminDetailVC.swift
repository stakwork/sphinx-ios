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
    case active
    case inactive
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
    
    
    @IBOutlet weak var statusButton: UIButton!
    @IBOutlet weak var badgeStatsLabel: UILabel!
    @IBOutlet weak var badgeStatsLabelHeight: NSLayoutConstraint!
    @IBOutlet weak var badgeStatsLabelBottomConstraint: NSLayoutConstraint!
    @IBOutlet weak var badgeStatsLabelTopConstraint: NSLayoutConstraint!
    
    private lazy var loadingViewController = LoadingViewController(backgroundColor: UIColor.clear)
    var presentationContext : BadgeDetailPresentationContext = .template
    var associatedBadge : Badge? = nil
    let pricePerBadge : Int = 10
    var badgeQuantity : Int = 100 {
        didSet{
            updateBadgeQuantities()
        }
    }
    
    
    override func viewDidLoad() {
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
        
    }
    
    func customizeBasedOnPresentationContext(){
        switch(presentationContext){
        case .template:
            saveBadgeButton.setTitle("badges.purchase-badges".localized, for: .normal)
            badgeActivationContainerView.isHidden = true
            badgeActivationContainerHeight.constant = 0
            badgeStatsLabelHeight.constant = 0
            badgeStatsLabelTopConstraint.constant = 0
            badgeStatsLabelBottomConstraint.constant = 0
            vcScrollView.contentSize = CGSize(width: self.view.frame.width, height: 650.0)
            break
        default:
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
                let leftString = String(format: "badges.badges-left".localized, badgesCreated)
                let fullText = "\(remainingAmountText) \(leftString)"
                
                let attributedString = NSMutableAttributedString(string: fullText)
                attributedString.addAttribute(.foregroundColor, value: UIColor.Sphinx.BodyInverted, range: NSRange(location: 0, length: remainingAmountText.count))
                
                badgeStatsLabel.attributedText = attributedString
                
                badgeActivateDeactivateLabel.text = (valid_badge.activationState == true) ? "badges.deactivate-badge".localized : "badges.activate-badge".localized
                badgeActivateDeactivateSwitch.isOn = valid_badge.activationState
            }
            vcScrollView.contentSize = CGSize(width: self.view.frame.width, height: 400.0)
            break
        }
    }
    
    static func instantiate() -> UIViewController {
        let viewController = StoryboardScene.BadgeManagement.badgeDetailViewController.instantiate()
        return viewController
    }

    
    func styleSubViews(){
        styleStatusButton()
        view.backgroundColor = UIColor.Sphinx.Body
        stepperMinusButton.setTitle("", for: .normal)
        stepperPlusButton.setTitle("", for: .normal)
        stepperMinusButton.backgroundColor = UIColor.Sphinx.LightBG
        stepperPlusButton.backgroundColor = UIColor.Sphinx.LightBG
        stepperPlaceholderView.backgroundColor = UIColor.Sphinx.DashboardSearch
        stepperPlaceholderView.layer.cornerRadius = 16.0
        stepperMinusButton.layer.cornerRadius = stepperMinusButton.layer.bounds.width / 2
        stepperPlusButton.layer.cornerRadius = stepperMinusButton.layer.bounds.width / 2
        quantityLabel.textColor = UIColor.Sphinx.SecondaryText
        quantityLabel.text = "badges.quantity".localized
        pricePerBadgeLabel.textColor = UIColor.Sphinx.SecondaryText
        pricePerBadgeLabel.text = "badges.price-per-badge".localized
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
        
        let viewController = ChatAttachmentViewController.instantiate(delegate: self)
        viewController.presentationContext = .fromBadgeCreateUpdate
        viewController.modalPresentationStyle = .overCurrentContext
        self.present(viewController, animated: false)
    }
    
    
    @IBAction func createBadgeButtonTap(_ sender: Any) {
        //Call API
        addChildVC(
            child: loadingViewController,
            container: self.view
        )
        
        if let valid_badge = self.associatedBadge{
            let titleText = "badges.creation-success-title".localized
            let messageText = String(format: "badges.creation-success-message".localized, badgeQuantity)
            API.sharedInstance.createTribeAdminBadge(
                badge: valid_badge,
                amount: self.badgeQuantity,
                callback: { success in
                    self.removeChildVC(child: self.loadingViewController)
                    AlertHelper.showAlert(
                    title: titleText,
                    message: "\(messageText) \(String(describing: valid_badge.name ?? "badges.your-badge".localized))",
                    completion: {
                        self.navigationController?.popViewController(animated: true)
                    })
                },
                errorCallback: {
                    self.removeChildVC(child: self.loadingViewController)
                    AlertHelper.showAlert(title: "Error", message: "Error creating this badge. Please try again.")
                })
        }
        else{
            //handle error
            self.removeChildVC(child: loadingViewController)
            AlertHelper.showAlert(title: "Error", message: "Error creating this badge. Please try again.")
        }
    }
    
    func styleStatusButton(){
        statusButton.layer.cornerRadius = statusButton.frame.height/2.0
        statusButton.isUserInteractionEnabled = false
        switch(presentationContext){
            case .active:
                statusButton.backgroundColor = UIColor.Sphinx.BodyInverted.withAlphaComponent(1.0)
                statusButton.setTitleColor(UIColor.Sphinx.Body, for: [.normal,.selected])
                
                let string = "active.upper".localized
                let attributedString = NSMutableAttributedString(string: string)
                attributedString.addAttribute(.foregroundColor, value: UIColor.Sphinx.Body, range: NSRange(location: 0, length: string.count))
                attributedString.addAttribute(.font, value: UIFont(name: "Roboto", size: 11.0), range: NSRange(location: 0, length: string.count))
                statusButton.titleLabel?.attributedText = attributedString
                break
            case .inactive:
                statusButton.backgroundColor = UIColor.Sphinx.PlaceholderText.withAlphaComponent(0.07)
                statusButton.setTitleColor(UIColor.Sphinx.SecondaryText, for: [.normal,.selected])
                
            let string = "inactive.upper".localized
                let attributedString = NSMutableAttributedString(string: string)
            attributedString.addAttribute(.foregroundColor, value: UIColor.Sphinx.SecondaryText, range: NSRange(location: 0, length: string.count))
                attributedString.addAttribute(.font, value: UIFont(name: "Roboto", size: 11.0), range: NSRange(location: 0, length: string.count))
                statusButton.titleLabel?.attributedText = attributedString
                
                break
            case .template:
                statusButton.backgroundColor = UIColor.Sphinx.PrimaryBlue.withAlphaComponent(1.0)
                statusButton.setTitleColor(UIColor.white, for: [.normal,.selected])
                
            let string = "template.upper".localized
                let attributedString = NSMutableAttributedString(string: string)
                attributedString.addAttribute(.foregroundColor, value: UIColor.white, range: NSRange(location: 0, length: string.count))
                attributedString.addAttribute(.font, value: UIFont(name: "Roboto", size: 10.0), range: NSRange(location: 0, length: string.count))
                statusButton.titleLabel?.attributedText = attributedString
                break
        }
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
        viewTitle.text = badge.name ?? ""
        badgeNameLabel.text = badge.name ?? ""
        badgeRequirementDescriptionLabel.text = badge.memo ?? ""
        
    }
    
    
    @IBAction func plusMinusButtonTouch(_ sender: Any) {
        let maxValue = 200
        let minValue = 0
        if let buttonSender = sender as? UIButton{
            var incrementValue = 0
            if buttonSender == stepperPlusButton{
                incrementValue = 1
            }
            else if buttonSender == stepperMinusButton{
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
    
    @IBAction func changedActivationState(_ sender: Any) {
        addChildVC(
            child: loadingViewController,
            container: self.view
        )
        
        badgeActivateDeactivateSwitch.isUserInteractionEnabled = false
        associatedBadge?.activationState = badgeActivateDeactivateSwitch.isOn
        let activationString = (badgeActivateDeactivateSwitch.isOn == true) ? "badges.activation-success".localized : "badges.deactivation-success".localized
        let failureString = (badgeActivateDeactivateSwitch.isOn == true) ? "activating" : "deactivating"
        if let valid_badge = associatedBadge{
            API.sharedInstance.changeActivationStateAdminBadgeTemplates(
            badge: valid_badge,
            callback: { success in
                self.removeChildVC(child: self.loadingViewController)
                if(success){
                    AlertHelper.showAlert(
                        title: "badges.success".localized,
                        message: activationString,
                        completion: {
                            self.navigationController?.popViewController(animated: true)
                    })
                }
                else{
                    self.badgeActivateDeactivateSwitch.isOn = !self.badgeActivateDeactivateSwitch.isOn
                    AlertHelper.showAlert(title: "Error", message: "There was an error \(failureString) the badge.")
                }
                self.badgeActivateDeactivateSwitch.isUserInteractionEnabled = true
            },
            errorCallback: {
                self.removeChildVC(child: self.loadingViewController)
                self.badgeActivateDeactivateSwitch.isOn = !self.badgeActivateDeactivateSwitch.isOn 
                AlertHelper.showAlert(title: "Error", message: "There was an error \(failureString) the badge.")
                self.badgeActivateDeactivateSwitch.isUserInteractionEnabled = true
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
    
    func shouldSendGiphy(message: String, data: Data) {
        
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
