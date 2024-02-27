//
//  PaymentTemplateViewController.swift
//  sphinx
//
//  Created by Tomas Timinskas on 12/03/2020.
//  Copyright © 2020 Sphinx. All rights reserved.
//

import UIKit
import SwiftyJSON

class PaymentTemplateViewController: CommonPaymentViewController {

    @IBOutlet weak var amountLabel: UITextField!
    @IBOutlet weak var unitLabel: UILabel!
    @IBOutlet weak var proceedButton: UIButton!
    @IBOutlet weak var messageField: UITextField!
    @IBOutlet weak var selectedImageView: UIImageView!
    @IBOutlet weak var imagesCollectionView: UICollectionView!
    @IBOutlet weak var selectedCircleView: UIView!
    @IBOutlet weak var groupTotalLabel: UILabel!
    @IBOutlet weak var loadingWheel: UIActivityIndicatorView!
    @IBOutlet weak var loadingTemplatesContainer: UIView!
    @IBOutlet weak var loadingTemplatesWheel: UIActivityIndicatorView!
    
    var loading = false {
        didSet {
            LoadingWheelHelper.toggleLoadingWheel(loading: loading, loadingWheel: loadingWheel, loadingWheelColor: UIColor.Sphinx.Text, view: view)
        }
    }
    
    var loadingTemplates = false {
        didSet {
            selectedCircleView.alpha = loadingTemplates ? 0.0 : 1.0
            loadingTemplatesContainer.alpha = loadingTemplates ? 1.0 : 0.0
            
            LoadingWheelHelper.toggleLoadingWheel(loading: loadingTemplates, loadingWheel: loadingTemplatesWheel, loadingWheelColor: UIColor.Sphinx.Text)
        }
    }
    
    var collectionDataSource : PaymentTemplatesDataSource!
    
    static func instantiate(
        contact: UserContact,
        chat: Chat? = nil,
        delegate: PaymentInvoiceDelegate?,
        paymentsViewModel: PaymentsViewModel
    ) -> PaymentTemplateViewController {
        
        let viewController = StoryboardScene.Chat.paymentTemplateViewController.instantiate()
        
        viewController.contact = contact
        viewController.delegate = delegate
        viewController.chat = chat
        viewController.paymentsViewModel = paymentsViewModel
        
        return viewController
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        proceedButton.addShadow(location: VerticalLocation.bottom, color: UIColor.Sphinx.GreenBorder, opacity: 1, radius: 0.5, bottomhHeight: 1.5)
        proceedButton.setBackgroundColor(color: UIColor.Sphinx.GreenBorder, forUIControlState: .selected)
        proceedButton.setBackgroundColor(color: UIColor.Sphinx.GreenBorder, forUIControlState: .highlighted)
        proceedButton.layer.cornerRadius = proceedButton.frame.size.height / 2
        proceedButton.clipsToBounds = true
        
        messageField.isUserInteractionEnabled = false
        amountLabel.isUserInteractionEnabled = false
        
        configurePayment()
        addCircleLine()
        loadTemplates()
    }
    
    @objc private func updateMessage(sender: UITextField) {
        paymentsViewModel.payment.message = sender.text
    }
    
    func addCircleLine() {
        self.selectedCircleView.addCircleLine(tag: "selected_circle", center: CGPoint(x: selectedCircleView.frame.size.width / 2, y: selectedCircleView.frame.size.height / 2), radius: CGFloat(34), lineWidth: 2.0)
        self.selectedCircleView.isUserInteractionEnabled = false
    }
    
    func configurePayment() {
        if let amount = paymentsViewModel.payment.amount {
            let amountString = amount.formattedWithSeparator
            amountLabel.text = amountString
            
//            let totalAmountString = amount.formattedWithSeparator
//            groupTotalLabel.text = contactsCount > 1 ? " \("Total") \(totalAmountString)" : ""
//            groupTotalLabel.text = ""
        }
        
        if let message = paymentsViewModel.payment.message, !message.isEmpty {
            messageField.text = message
        }
    }
    
    func loadTemplates() {
        loadingTemplates = true
        
        API.sharedInstance.getPaymentTemplates(token: UserDefaults.Keys.attachmentsToken.get(defaultValue: ""), callback: { templates in
            self.configureCollectionView(images: templates)
        }, errorCallback: {
            AlertHelper.showAlert(title: "generic.error.title".localized, message: "generic.error.message".localized)
        })
    }
    
    func configureCollectionView(images: [ImageTemplate]) {
        imagesCollectionView.registerCell(PaymentTemplateCollectionViewCell.self)
        collectionDataSource = PaymentTemplatesDataSource(collectionView: imagesCollectionView, delegate: self, images: images)

        imagesCollectionView.delegate = collectionDataSource
        imagesCollectionView.dataSource = collectionDataSource
        imagesCollectionView.reloadData()
        
        imagesCollectionView.scrollToItem(at: IndexPath(row: 1, section: 0), at: .centeredHorizontally, animated: true)
        selectedImageView.tintColor = UIColor.Sphinx.PlaceholderText
        selectedImageView.tintColorDidChange()
        
        if images.count > 0 {
            setSelectedImage(image: images[0])
        }
    }
    
    func setSelectedImage(image: ImageTemplate?) {
        if paymentsViewModel.payment.muid == image?.muid {
            return
        }
        
        paymentsViewModel.payment.muid = image?.muid
        
        var imageContentmode:UIView.ContentMode = .scaleAspectFit
        
        if let width = image?.width, let height = image?.height {
            imageContentmode = width > height ? .scaleAspectFill : .scaleAspectFit
            paymentsViewModel.payment.dim = "\(width)x\(height)"
        } else {
            paymentsViewModel.payment.dim = nil
        }
        
        if let muid = image?.muid {
            setImage(image: nil, contentMode: imageContentmode)
            
            MediaLoader.loadTemplate(row: 0, muid: muid, completion: { (_, muid, image) in
                if muid != self.paymentsViewModel.payment.muid {
                    return
                }
                self.setImage(image: image, contentMode: imageContentmode)
            })
        } else {
            setImage(image: UIImage(named: "noTemplate"), contentMode: .center)
            selectedImageView.tintColor = UIColor.Sphinx.WashedOutReceivedText
            selectedImageView.tintColorDidChange()
        }
    }
    
    func setImage(image: UIImage?, contentMode: UIView.ContentMode) {
        selectedImageView.contentMode = contentMode
        selectedImageView.image = image
        loadingTemplates = false
    }
    
    @IBAction func proceedButtonTouched() {
        loading = true
        
        guard let validChat = chat,
            paymentsViewModel.validatePayment(contact: contact),
              let selectedImage = selectedImageView.image
         else{
            loading = false
            AlertHelper.showAlert(title: "generic.error.title".localized, message: "generic.error.message".localized)
            return
        }
        
        let params = TransactionMessage.getPaymentParamsFor(
            payment: paymentsViewModel.payment,
            contact: contact,
            chat: chat
        )
        SphinxOnionManager.sharedInstance.sendDirectPaymentMessage(params: params, chat: validChat, image: selectedImage) { success, _ in
            if(success){
                self.shouldDismissView()
            }
            else{
                AlertHelper.showAlert(title: "generic.error.title".localized, message: "generic.error.message".localized, completion: {
                    self.shouldDismissView()
                })
            }
        }
    }
    
    @IBAction func closeButtonTouched() {
        dismissView()
    }
    
    @IBAction func backButtonTouched() {
        self.navigationController?.popViewController(animated: true)
    }
}

extension PaymentTemplateViewController : PaymentTemplatesDSDelegate {
    func didSelectImage(image: ImageTemplate?) {
        setSelectedImage(image: image)
    }
}
