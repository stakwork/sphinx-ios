//
//  ChatAttachmentViewController.swift
//  sphinx
//
//  Created by Tomas Timinskas on 28/11/2019.
//  Copyright © 2019 Sphinx. All rights reserved.
//

import UIKit
import AVKit
import GiphyUISDK
import SDWebImageFLPlugin
import MobileCoreServices

protocol BackCameraVC {}

protocol AttachmentsDelegate: class {
    func willDismissPresentedVC()
    func shouldStartUploading(attachmentObject: AttachmentObject)
    func shouldSendGiphy(message: String)
    func didCloseReplyView()
    func didTapSendButton()
    func didTapReceiveButton()
}

class ChatAttachmentViewController: UIViewController, BackCameraVC {
    
    weak var delegate: AttachmentsDelegate?
    
    @IBOutlet weak var bottomView: UIView!
    @IBOutlet weak var headerContainer: UIView!
    @IBOutlet weak var viewTitle: UILabel!
    @IBOutlet weak var previewImageView: SDAnimatedImageView!
    @IBOutlet weak var containerBottomConstraint: NSLayoutConstraint!
    @IBOutlet weak var accessoryViewContainer: UIView!
    @IBOutlet weak var optionsContainer: UIView!
    @IBOutlet weak var optionsContainerBottomConstraint: NSLayoutConstraint!
    @IBOutlet weak var accessoryViewHeightConstraint: NSLayoutConstraint!
    @IBOutlet weak var paidMessageOptionContainer: UIView!
    @IBOutlet weak var requestOptionContainer: UIView!
    @IBOutlet weak var sendOptionContainer: UIView!
    @IBOutlet weak var sendOptionTitle: UILabel!
    
    @IBOutlet weak var attachmentPriceVCContainer: UIView!
    @IBOutlet weak var setPriceContainer: UIView!
    @IBOutlet weak var priceLabel: UILabel!
    @IBOutlet weak var priceUnitLabel: UILabel!
    
    @IBOutlet weak var paidMessagePreviewVCContainer: UIView!
    @IBOutlet weak var fileInfoContainer: UIView!
    @IBOutlet weak var fileInfoView: FileInfoView!
    @IBOutlet weak var loadingWheel: UIActivityIndicatorView!
    
    public static let kFieldPlaceHolder = "optional.message.placeholder".localized
    
    var priceVC : AttachmentPriceViewController!
    var previewVC : PaidMessagePreviewViewController?
    let accessoryView = ChatAccessoryView(frame: CGRect(x: 0, y: 0, width: WindowsManager.getWindowWidth(), height: ChatAccessoryView.kAccessoryViewDefaultHeight))
    let giphyHelper = GiphyHelper()
    
    var selectedImage: UIImage?
    var selectedAnimatedImage: SDAnimatedImage?
    var selectedVideo: Data?
    var selectedGiphy: GiphyUISDK.GPHMedia?
    var selectedFileData: Data?
    var fileName: String?
    
    var imagePickerManager = ImagePickerManager.sharedInstance
    var progressCompleteWidth: CGFloat = 240.0
    let kOptionsBottomViewConstant: CGFloat = -444.0
    
    var replyingMessage: TransactionMessage? = nil
    var text: String? = nil
    
    var price: Int = 0
    var chat: Chat? = nil
    
    public enum OptionsButton: Int {
        case Camera
        case Library
        case Gif
        case PDF
        case Message
        case Request
        case Send
    }
    
    var loading = false {
        didSet {
            LoadingWheelHelper.toggleLoadingWheel(loading: loading, loadingWheel: loadingWheel, loadingWheelColor: UIColor.white, view: view)
        }
    }
    
    static func instantiate(delegate: AttachmentsDelegate, chat: Chat?, text: String? = nil, replyingMessage: TransactionMessage? = nil) -> ChatAttachmentViewController {
        let viewController = StoryboardScene.Chat.chatAttachmentViewController.instantiate()
        viewController.replyingMessage = replyingMessage
        viewController.text = text
        viewController.delegate = delegate
        viewController.chat = chat
        
        return viewController
    }

    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.view.alpha = 0.0
        viewTitle.addTextSpacing(value: 2)
        
//        setupPriceViews()
        disablePriceFunctionality()
        
        headerContainer.addShadow(offset: CGSize(width: 0, height: 3), opacity: 0.2)

        paidMessageOptionContainer.alpha = isButtonDisabled(option: .Message) ? 0.4 : 1.0
        requestOptionContainer.alpha = isButtonDisabled(option: .Request) ? 0.4 : 1.0
        sendOptionContainer.alpha = isButtonDisabled(option: .Send) ? 0.4 : 1.0
        
        addAccessoryView()
        addSwipeToDismiss()
        
        imagePickerManager.configurePicker(vc: self)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        UIView.animate(withDuration: 0.2, animations: {
            self.view.alpha = 1.0
        }, completion: { _ in
            self.toggleOptionsContainer(show: true)
        })
    }
    
    func addSwipeToDismiss() {
        let swipeUp = UISwipeGestureRecognizer(target: self, action: #selector(self.handleSwipe(_:)))
        swipeUp.direction = .down
        self.view.addGestureRecognizer(swipeUp)
    }
    
    @objc func handleSwipe(_ sender: UISwipeGestureRecognizer? = nil) {
        accessoryView.shouldDismissKeyboard()
    }
    
    func addAccessoryView() {
        accessoryView.delegate = self
        accessoryView.setupForAttachments(with: self.text)
        accessoryView.configureReplyFor(message: replyingMessage)
        accessoryView.animateElements(active: true)
        accessoryView.hide()
        
        accessoryViewHeightConstraint.constant = accessoryView.viewContentSize().height
        
        accessoryView.translatesAutoresizingMaskIntoConstraints = false
        let bottomConstraint = NSLayoutConstraint(item: accessoryView, attribute: .bottom, relatedBy: .equal, toItem: accessoryViewContainer, attribute: .bottom, multiplier: 1, constant: 0.0)
        let leftConstraint = NSLayoutConstraint(item: accessoryView, attribute: .left, relatedBy: .equal, toItem: accessoryViewContainer, attribute: .left, multiplier: 1, constant: 0.0)
        let rightConstraint = NSLayoutConstraint(item: accessoryView, attribute: .right, relatedBy: .equal, toItem: accessoryViewContainer, attribute: .right, multiplier: 1, constant: 0.0)
        accessoryViewContainer.addSubview(accessoryView)
        accessoryViewContainer.addConstraints([bottomConstraint, leftConstraint, rightConstraint])
        accessoryViewContainer.layoutIfNeeded()
    }
    
    
    func showPriceContainer() {
    //  ⚠️ Tentatively disabled in order to comply with our current App Store review approval needs.
//        setPriceContainer.isHidden = false
    }
    
    
    func showFileInfoContainer() {
        fileInfoContainer.isHidden = false
    }
    
    func toggleOptionsContainer(show: Bool, withCompletion completion: (() -> ())? = nil) {
        let finalBottomConstraint:CGFloat = show ? 0 : kOptionsBottomViewConstant
        
        if finalBottomConstraint == optionsContainerBottomConstraint.constant {
            dismissView(withCompletion: completion)
            return
        }
        
        optionsContainerBottomConstraint.constant = finalBottomConstraint
        
        UIView.animate(withDuration: 0.2, animations: {
            self.bottomView.alpha = show ? 1.0 : 0.0
            self.optionsContainer.superview?.layoutIfNeeded()
        }, completion: { _ in
            completion?()
        })
    }
    
    func hideOptionsContainer() {
        bottomView.alpha = 0.0
        optionsContainerBottomConstraint.constant = kOptionsBottomViewConstant
        optionsContainer.superview?.layoutIfNeeded()
    }
    
    func dismissView(withCompletion completion: (() -> ())? = nil) {
        previewVC?.removeProvisionalMessage()
        accessoryView.removeKeyboardObservers()
        
        UIView.animate(withDuration: 0.2, animations: {
            self.view.alpha = 0.0
        }, completion: { _ in
            if let completion = completion {
                self.dismiss(animated: false, completion: {
                    completion()
                })
            } else {
                self.delegate?.willDismissPresentedVC()
                self.dismiss(animated: false, completion: {})
            }
        })
    }
    
    func isValidAttachment(type: AttachmentsManager.AttachmentType, text: String?) -> (Bool, String) {
        if type == AttachmentsManager.AttachmentType.Text {
            if price <= 0 {
                return (false, "price.required".localized)
            } else if (text?.isEmpty ?? true) {
                return (false, "message.required".localized)
            }
        }
        return (true, "")
    }
    
    func uploadAndSend(message: String? = nil) {
        let fixedImage = selectedImage?.fixedOrientation()
        let (data, type, messageContent, paidMessage) = getDataAndType(text: message)
        let isValid = isValidAttachment(type: type, text: paidMessage)
        
        if let data = data, isValid.0 {
            let (key, encryptedData) = SymmetricEncryptionManager.sharedInstance.encryptData(data: data)
            if let encryptedData = encryptedData {
                let attachmentObject = AttachmentObject(data: encryptedData, fileName: fileName, mediaKey: key, type: type, text: messageContent, paidMessage: paidMessage, image: fixedImage, price: price)
                
                delegate?.shouldStartUploading(attachmentObject: attachmentObject)
                dismissView()
            }
        } else {
            accessoryView.setTextBackAndDismissKeyboard(text: message ?? "")
            NewMessageBubbleHelper().showGenericMessageView(text: isValid.1)
        }
    }
    
    func getDataAndType(text: String? = nil) -> (Data?, AttachmentsManager.AttachmentType, String?, String?) {
        if let video = selectedVideo {
            return (video, AttachmentsManager.AttachmentType.Video, text, nil)
        } else if let animatedImage = selectedAnimatedImage, let gifData = animatedImage.animatedImageData {
            return (gifData, AttachmentsManager.AttachmentType.Gif, text, nil)
        } else if let fileData = selectedFileData {
            if fileName?.contains(".pdf") ?? false {
                return (fileData, AttachmentsManager.AttachmentType.PDF, text, nil)
            } else {
                return (fileData, AttachmentsManager.AttachmentType.GenericFile, text, nil)
            }
        } else if let image = selectedImage?.fixedOrientation() {
            if let imgData = image.jpegData(compressionQuality: 0.5) {
                return (imgData, AttachmentsManager.AttachmentType.Photo, text, nil)
            }
        } else if let text = text {
            return (text.data(using: .utf8), AttachmentsManager.AttachmentType.Text, nil, text)
       }
        return (nil, AttachmentsManager.AttachmentType.Text, nil, nil)
    }
    
    func showErrorAlert() {
        AlertHelper.showAlert(title: "generic.error.title".localized, message: "generic.error.message".localized, completion: {
            self.closeButtonTouched()
        })
    }
    
    @IBAction func setPriceButtonTouched() {
        accessoryView.shouldDismissKeyboard()
        showPriceVC()
    }
    
    @IBAction func optionButtonTouched(_ sender: UIButton) {
        view.backgroundColor = UIColor.black.withAlphaComponent(0.25)
        
        if let option = OptionsButton(rawValue: sender.tag) {
            switch(option) {
            case OptionsButton.Camera:
                imagePickerManager.showCamera(mode: .photo)
            case OptionsButton.Library:
                imagePickerManager.showPhotoLibrary()
            case OptionsButton.Gif:
                optionButtonsTouched(option: OptionsButton.Gif)
            case OptionsButton.PDF:
                showFilesBrowser()
            case OptionsButton.Message:
                showMessageLabel()
            case OptionsButton.Request:
                optionButtonsTouched(option: OptionsButton.Request)
            case OptionsButton.Send:
                optionButtonsTouched(option: OptionsButton.Send)
            }
        }
    }
    
    func showFilesBrowser() {
        let browser = UIDocumentPickerViewController(documentTypes: ["public.item"], in: .import)
        browser.modalPresentationStyle = .overCurrentContext
        browser.delegate = self
        self.present(browser, animated: true, completion: nil)
    }
    
    func optionButtonsTouched(option: OptionsButton) {
        if isButtonDisabled(option: option) {
            return
        }
        
        if option == OptionsButton.Gif {
            presentGiphy()
            return
        }
        
        toggleOptionsContainer(show: false, withCompletion: {
            self.dismissView(withCompletion: {
                switch(option) {
                case OptionsButton.Request:
                    self.delegate?.didTapReceiveButton()
                case OptionsButton.Send:
                    self.delegate?.didTapSendButton()
                default:
                    break
                }
            })
        })
    }
    
    func presentGiphy() {
        let darkMode =  traitCollection.userInterfaceStyle == .dark
        let giphyVC = giphyHelper.getGiphyVC(darkMode: darkMode, delegate: self)
        present(giphyVC, animated: true, completion: {})
    }
    
    @IBAction func optionsCancelButtonTouched() {
        toggleOptionsContainer(show: false, withCompletion:{
            self.dismissView()
        })
    }
    
    @IBAction func closeButtonTouched() {
        dismissView()
    }
    
    
    /// Tentatively disables the visibility and functionality of the "Set Price"
    /// button in order to comply with our current App Store review approval needs.
    private func disablePriceFunctionality() {
        attachmentPriceVCContainer.isHidden = true
        setPriceContainer.isHidden = true
        setPriceContainer.subviews.forEach { $0.isHidden = true }
    }
    
    private func setupPriceViews() {
        setPriceContainer.layer.cornerRadius = 5
        attachmentPriceVCContainer.layer.cornerRadius = 10
        attachmentPriceVCContainer.layer.borderWidth = 1
        attachmentPriceVCContainer.layer.borderColor = UIColor.Sphinx.ReceivedBubbleBorder.resolvedCGColor(with: self.view)
        attachmentPriceVCContainer.clipsToBounds = true
    }
}
