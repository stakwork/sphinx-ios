//
//  CreateInvoiceDetailsViewController.swift
//  sphinx
//
//  Created by Tomas Timinskas on 20/03/2020.
//  Copyright © 2020 Sphinx. All rights reserved.
//

import UIKit

class CreateInvoiceDetailsViewController: CommonPaymentViewController {

    @IBOutlet weak var invoiceImageView: UIImageView!
    @IBOutlet weak var invoiceName: UILabel!
    @IBOutlet weak var invoiceAmount: UILabel!
    @IBOutlet weak var loadingWheel: UIActivityIndicatorView!
    @IBOutlet weak var confirmButton: UIButton!
    
    var loading = false {
        didSet {
            LoadingWheelHelper.toggleLoadingWheel(loading: loading, loadingWheel: loadingWheel, loadingWheelColor: UIColor.white, view: view)
        }
    }
    
    var invoiceDetails: InvoiceManager.InvoiceDetails!
    
    static func instantiate(
        invoiceDetails: InvoiceManager.InvoiceDetails,
        delegate: PaymentInvoiceDelegate? = nil
    ) -> CreateInvoiceDetailsViewController {
        let viewController = StoryboardScene.QRCodeDetail.createInvoiceDetailsViewController.instantiate()
        viewController.invoiceDetails = invoiceDetails
        viewController.delegate = delegate
        return viewController
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setStatusBarColor()
        
        confirmButton.setBackgroundColor(color: UIColor.Sphinx.PrimaryBlueBorder, forUIControlState: .highlighted)
        confirmButton.setBackgroundColor(color: UIColor.Sphinx.PrimaryBlueBorder, forUIControlState: .selected)
        confirmButton.layer.cornerRadius = confirmButton.frame.size.height / 2
        confirmButton.clipsToBounds = true
        
        completeInvoiceDetails()
    }
    
    func completeInvoiceDetails() {
        if let invoiceDetails = invoiceDetails {
            if let name = invoiceDetails.name {
                invoiceName.text = name
            }
            
            if let amount = invoiceDetails.amount {
                let amountString = amount.formattedWithSeparator
                invoiceAmount.text = amountString
            }
            
            if let imageUrl = invoiceDetails.imgurl?.trim(), let nsUrl = URL(string: imageUrl), imageUrl != "" {
                invoiceImageView.contentMode = .scaleAspectFill
                invoiceImageView.layer.cornerRadius = 5
                MediaLoader.asyncLoadImage(imageView: invoiceImageView, nsUrl: nsUrl, placeHolderImage: UIImage(named: "profile_avatar"))
            } else {
                invoiceImageView.layer.cornerRadius = invoiceImageView.frame.size.height / 2
                invoiceImageView.image = UIImage(named: "profile_avatar")
            }
        }
    }
    
    @IBAction func confirmButtonTouched() {
        loading = true
        createPaymentRequest()
    }
    
    private func createPaymentRequest() {
        var parameters = [String : AnyObject]()
        
        if let amount = invoiceDetails.amount {
            parameters["amount"] = amount as AnyObject?
        }
        
        API.sharedInstance.createInvoice(parameters: parameters, callback: { message, invoice in
            if let message = message {
                self.createLocalMessages(message: message)
            } else if let invoice = invoice {
                self.presentInvoiceDetailsVC(invoiceString: invoice)
            }
        }, errorCallback: {
            self.createLocalMessages(message: nil)
        })
    }
    
    private func presentInvoiceDetailsVC(invoiceString: String) {
        let amount = invoiceDetails.amount ?? 0
        let qrCodeDetailViewModel = QRCodeDetailViewModel(qrCodeString: invoiceString, amount: amount, viewTitle: "payment.request".localized)
        let viewController = QRCodeDetailViewController.instantiate(with: qrCodeDetailViewModel, delegate: delegate)
        self.navigationController?.pushViewController(viewController, animated: true)
    }
    
    @IBAction func closeButtonTouched() {
        dismissView()
    }
}
