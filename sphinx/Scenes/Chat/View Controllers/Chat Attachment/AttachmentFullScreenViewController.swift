//
//  ImageFullScrennViewController.swift
//  sphinx
//
//  Created by Tomas Timinskas on 31/01/2020.
//  Copyright © 2020 Sphinx. All rights reserved.
//

import UIKit
import PDFKit
import MobileCoreServices

protocol CanRotate {}

class AttachmentFullScreenViewController: UIViewController, CanRotate {
    
    @IBOutlet weak var fullScreenImageView: FullScreenImageView!
    @IBOutlet weak var backButton: UIButton!
    @IBOutlet weak var pdfHeaderView: UIView!
    @IBOutlet weak var shareButton: UIButton!
    @IBOutlet weak var fileNameLabel: UILabel!
    
    var message: TransactionMessage!
    var purchaseAcceptMessage: TransactionMessage?
    
    var pdfDocument: PDFDocument? = nil
    var webViewImageURL:URL? = nil
    
    var animated = true
    
    static func instantiate(
        messageId: Int,
        animated: Bool = true,
        webViewImageUrl:URL?=nil
    ) -> AttachmentFullScreenViewController? {
        
        if let message = TransactionMessage.getMessageWith(id: messageId) {
            
            let viewController = StoryboardScene.Chat.attachmentFullScreenViewController.instantiate()
            viewController.webViewImageURL = webViewImageUrl
            viewController.message = message
            viewController.animated = animated
            viewController.purchaseAcceptMessage = message.getPurchaseAcceptItem()
            return viewController
        }
        
        return nil
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if message.isPDF() {
            showPDF()
        }
        else if let _ = webViewImageURL{
            showWebViewImage()
        }
        else {
            showImage()
        }
    }
    
    func showWebViewImage() {
        guard let webViewImageURL = webViewImageURL else{
            return
        }
        fullScreenImageView.isHidden = false
        pdfHeaderView.isHidden = true
        
        self.view.backgroundColor = UIColor.black.withAlphaComponent(0.6)
        fullScreenImageView.configureImageScrollView()
        fullScreenImageView.showWebViewImage(url: webViewImageURL )
        
        let tap = TouchUpGestureRecognizer(target: self, action: #selector(self.handleTap(_:)))
        self.view.addGestureRecognizer(tap)
    }
    
    func showImage() {
        fullScreenImageView.isHidden = false
        pdfHeaderView.isHidden = true
        
        self.view.backgroundColor = UIColor.black.withAlphaComponent(0.6)
        fullScreenImageView.configureImageScrollView()
        fullScreenImageView.showImage(message: message)
        
        let tap = TouchUpGestureRecognizer(target: self, action: #selector(self.handleTap(_:)))
        self.view.addGestureRecognizer(tap)
    }
    
    func showPDF() {
        fullScreenImageView.isHidden = true
        pdfHeaderView.isHidden = false
        
        if let url = purchaseAcceptMessage?.getMediaUrlFromMediaToken() ?? message.getMediaUrlFromMediaToken() {
            
            let pdfView = PDFView(frame: getPDFViewFrame())
            pdfView.autoScales = true
            self.view.addSubview(pdfView)
            self.view.sendSubviewToBack(pdfView)
            
            MediaLoader.loadFileData(
                url: url,
                message: message,
                mediaKey: purchaseAcceptMessage?.mediaKey ?? message.mediaKey,
                completion: { (_, data) in
                    self.fileNameLabel.text = self.message.mediaFileName ?? "file.pdf"
                    self.pdfDocument = PDFDocument(data: data)
                    pdfView.document = self.pdfDocument
                },
                errorCompletion: { _ in }
            )
        }
    }
    
    func getPDFViewFrame() -> CGRect {
        let screenSize = UIScreen.main.bounds
        let headerHeight = pdfHeaderView.frame.height + getWindowInsets().top
        return CGRect(x: 0, y: headerHeight, width: screenSize.width, height: screenSize.height - headerHeight)
    }
    
    func deleteLocalPDF() {
        if let _ = pdfDocument, let url = URL(string: message.mediaFileName ?? "file.pdf") {
            do {
                try FileManager.default.removeItem(at: url)
            } catch let error {
                print(error)
            }
        }
    }
    
    @objc func handleTap(_ sender: TouchUpGestureRecognizer? = nil) {
        backButtonTouched()
    }
    
    @IBAction func shareButtonTouched() {
        if let pdfData = pdfDocument?.dataRepresentation(),
            let pdfUrl = MediaLoader.saveFileInMemory(
                data: pdfData,
                name: message.mediaFileName ?? "file.pdf"
            ) {
                let activityVC = UIActivityViewController(activityItems: [pdfUrl], applicationActivities: nil)
                activityVC.popoverPresentationController?.sourceView = self.shareButton
                self.present(activityVC, animated: true, completion: nil)
            }
    }
    
    @IBAction func backButtonTouched() {
        deleteLocalPDF()
        
        if !UIDevice.current.isIpad {
            UIDevice.current.setValue(Int(UIInterfaceOrientation.portrait.rawValue), forKey: "orientation")
            
        }
        
        self.dismiss(animated: animated, completion: {
            WindowsManager.sharedInstance.removeCoveringWindow()
        })
    }
}
