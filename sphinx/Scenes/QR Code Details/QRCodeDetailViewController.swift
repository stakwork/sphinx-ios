//
//  Zap
//
//  Created by Tomas Timinskas on 20.01.18.
//  Copyright © 2018 Otto Suess. All rights reserved.
//

import UIKit

final class QRCodeDetailViewController: UIViewController {
    
    @IBOutlet private weak var qrCodeImageView: UIImageView!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var amountLabelContainer: UIView!
    @IBOutlet weak var amountLabel: UILabel!
    @IBOutlet weak var invoiceStringLabel: UILabel!
    @IBOutlet private weak var shareButton: UIButton!
    @IBOutlet private weak var copyButton: UIButton!
    @IBOutlet weak var paidLabelContainer: UIView!
    
    public weak var delegate: PaymentInvoiceDelegate?
    public weak var presentedVCDelegate: PresentedViewControllerDelegate?
    
    private var viewModel: QRCodeDetailViewModel?
    
    static func instantiate(
        with qrCodeDetailViewModel: QRCodeDetailViewModel,
        delegate: PaymentInvoiceDelegate? = nil,
        presentedVCDelegate: PresentedViewControllerDelegate? = nil
    ) -> QRCodeDetailViewController {
        let viewController = StoryboardScene.QRCodeDetail.qrCodeDetailViewController.instantiate()
        viewController.viewModel = qrCodeDetailViewModel
        viewController.delegate = delegate
        viewController.presentedVCDelegate = presentedVCDelegate
        return viewController
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        guard let viewModel = viewModel else { fatalError("No ViewModel set.") }
        
        shareButton.layer.cornerRadius = shareButton.frame.size.height / 2
        shareButton.setBackgroundColor(color: UIColor.Sphinx.PrimaryBlue, forUIControlState: .normal)
        shareButton.setBackgroundColor(color: UIColor.Sphinx.PrimaryBlueBorder, forUIControlState: .highlighted)
        shareButton.setBackgroundColor(color: UIColor.Sphinx.PrimaryBlueBorder, forUIControlState: .selected)
        shareButton.clipsToBounds = true
        
        copyButton.layer.cornerRadius = copyButton.frame.size.height / 2
        copyButton.setBackgroundColor(color: UIColor.Sphinx.PrimaryBlue, forUIControlState: .normal)
        copyButton.setBackgroundColor(color: UIColor.Sphinx.PrimaryBlueBorder, forUIControlState: .highlighted)
        copyButton.setBackgroundColor(color: UIColor.Sphinx.PrimaryBlueBorder, forUIControlState: .selected)
        copyButton.clipsToBounds = true
        
        paidLabelContainer.layer.cornerRadius = 5
        paidLabelContainer.layer.borderWidth = 4
        paidLabelContainer.layer.borderColor = UIColor.Sphinx.PrimaryGreen.resolvedCGColor(with: self.view)
        
        amountLabelContainer.isHidden = true
        
        if let title = viewModel.viewTitle {
            titleLabel.text = title.uppercased()
        }
        
        titleLabel.addTextSpacing(value: 2)
        
        if let qrCodeString = viewModel.qrCodeString {
            qrCodeImageView?.image = UIImage.qrCode(from: qrCodeString)
            invoiceStringLabel.text = qrCodeString
        }
        
        if let amount = viewModel.amount, amount > 0 {
            amountLabelContainer.isHidden = false
            amountLabel.text = "\(amount) sats"
        }
    }
    
    func togglePaidContainer(invoice: String) {
        if let qrCodeString = viewModel?.qrCodeString, qrCodeString == invoice {
            UIView.animate(withDuration: 0.3, animations: {
                self.paidLabelContainer.alpha = 1.0
            })
        }
    }
    
    @IBAction func copyQrCodeTapped() {
        guard let address = viewModel?.qrCodeString else { return }
        guard let title = viewModel?.viewTitle else { return }
    
        UISelectionFeedbackGenerator().selectionChanged()
        let message = String(format: "x.copied.clipboard".localized, title)
        ClipboardHelper.copyToClipboard(text: address, message: message)
    }
    
    private func dismissParent() {
        delegate?.willDismissPresentedView?(paymentCreated: false)
        presentedVCDelegate?.viewWillDismiss()
        
        dismiss(animated: true, completion: nil)
    }
    
    @IBAction private func doneButtonTapped() {
        dismissParent()
    }
    
    @IBAction func shareButtonTapped() {
        guard let address = viewModel?.qrCodeString else { return }

        let items: [Any] = [address]
        
        let activityViewController = UIActivityViewController(activityItems: items, applicationActivities: nil)
        present(activityViewController, animated: true, completion: nil)
    }
}
