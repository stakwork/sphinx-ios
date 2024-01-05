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
import CoreData

protocol BackCameraVC {}

protocol AttachmentsDelegate: class {
    func willDismissPresentedVC()
    func shouldStartUploading(attachmentObject: AttachmentObject)
    func shouldSendGiphy(message: String, data: Data)
    func didCloseReplyView()
    func didTapSendButton()
    func didTapReceiveButton()
}

public enum ChatAttachmentVCPresentationContext{
    case fromMessages
    case fromBadgeCreateUpdate
}

class ChatAttachmentViewController: NewKeyboardHandlerViewController, BackCameraVC {
    
    weak var delegate: AttachmentsDelegate?
    
    @IBOutlet weak var headerContainer: UIView!
    @IBOutlet weak var viewTitle: UILabel!
    @IBOutlet weak var previewImageView: SDAnimatedImageView!
    @IBOutlet weak var optionsContainer: UIView!
    @IBOutlet weak var optionsContainerBottomConstraint: NSLayoutConstraint!
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
    
    @IBOutlet weak var contentStackView: UIStackView!
    @IBOutlet weak var bottomView: UIView!
    @IBOutlet weak var newChatAccessoryView: NewChatAccessoryView!
    
    public static let kFieldPlaceHolder = "optional.message.placeholder".localized
    
    var priceVC : AttachmentPriceViewController!
    var previewVC : PaidMessagePreviewViewController?
    let giphyHelper = GiphyHelper()
    
    var selectedImage: UIImage?
    var selectedAnimatedImage: SDAnimatedImage?
    var selectedVideo: Data?
    var selectedGiphy: (GiphyUISDK.GPHMedia, Data)?
    var selectedFileData: Data?
    var fileName: String?
    
    var imagePickerManager = ImagePickerManager.sharedInstance
    var progressCompleteWidth: CGFloat = 240.0
    let kOptionsBottomViewConstant: CGFloat = -444.0
    
    var replyingMessage: TransactionMessage? = nil
    var text: String? = nil
    
    var price: Int = 0
    var chat: Chat? = nil
    var isThread: Bool = false
    
    var presentationContext : ChatAttachmentVCPresentationContext = .fromMessages
    
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
    
    static func instantiate(
        delegate: AttachmentsDelegate,
        chatId: Int? = nil,
        text: String? = nil,
        replyingMessageId: Int? = nil,
        isThread: Bool = false
    ) -> ChatAttachmentViewController {
        
        let viewController = StoryboardScene.Chat.chatAttachmentViewController.instantiate()
        
        if let replyingMessageId = replyingMessageId {
            viewController.replyingMessage = TransactionMessage.getMessageWith(id: replyingMessageId)
        }
        
        viewController.text = text
        viewController.delegate = delegate
        viewController.isThread = isThread
        
        if let chatId = chatId {
            viewController.chat = Chat.getChatWith(id: chatId)
        }
        
        return viewController
    }

    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.view.alpha = 0.0
        viewTitle.addTextSpacing(value: 2)
        
        setupPriceViews()
        
        headerContainer.addShadow(offset: CGSize(width: 0, height: 3), opacity: 0.2)

        paidMessageOptionContainer.alpha = isButtonDisabled(option: .Message) ? 0.4 : 1.0
        requestOptionContainer.alpha = isButtonDisabled(option: .Request) ? 0.4 : 1.0
        sendOptionContainer.alpha = isButtonDisabled(option: .Send) ? 0.4 : 1.0
        
        setupAccessoryView()
        addSwipeToDismiss()
        imagePickerManager.configurePicker(vc: self)
        setupForBadges()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        animateView()
    }
    
    func addSwipeToDismiss() {
        let swipeUp = UISwipeGestureRecognizer(target: self, action: #selector(self.handleSwipe(_:)))
        swipeUp.direction = .down
        self.view.addGestureRecognizer(swipeUp)
    }
    
    @objc func handleSwipe(_ sender: UISwipeGestureRecognizer? = nil) {
        view.endEditing(true)
    }
    
    func setupAccessoryView() {
        newChatAccessoryView.setupForAttachments(with: self.text, andDelegate: self)
        newChatAccessoryView.configureReplyViewFor(message: replyingMessage, withDelegate: self)
    }
    
    func showPriceContainer() {
        setPriceContainer.isHidden = isThread
    }
    
    func setupForBadges(){
        if (presentationContext != .fromBadgeCreateUpdate) {
            return
        }
        self.paidMessageOptionContainer.isHidden = true
        self.requestOptionContainer.isHidden = true
        self.sendOptionContainer.isHidden = true
        self.viewTitle.attributedText = NSAttributedString(string: "Upload an Icon")
    }
    
    func showFileInfoContainer() {
        fileInfoContainer.isHidden = false
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
    
    func uploadAndSend(
        message: String? = nil,
        completion: ((Bool) -> ())? = nil
    ) {
        let fixedImage = selectedImage?.fixedOrientation()
        let (data, type, messageContent, paidMessage) = getDataAndType(text: message)
        let isValid = isValidAttachment(type: type, text: paidMessage)
        
        if let data = data, isValid.0 {
            let (key, encryptedData) = SymmetricEncryptionManager.sharedInstance.encryptData(data: data)
            
            if let encryptedData = encryptedData {
                
                let attachmentObject = AttachmentObject(
                    data: encryptedData,
                    fileName: fileName,
                    mediaKey: key,
                    type: type,
                    text: messageContent,
                    paidMessage: paidMessage,
                    image: fixedImage,
                    price: price,
                    contactPubkey: chat?.getContact()?.publicKey
                )
                
                delegate?.shouldStartUploading(attachmentObject: attachmentObject)
                dismissView()
                completion?(true)
            }
        } else {
            completion?(false)
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
        view.endEditing(true)
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
                optionButtonsTouched(option: OptionsButton.Message)
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
            
            if option == OptionsButton.Message {
                self.showMessageLabel()
                return
            }
            
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
    
    private func setupPriceViews() {
        setPriceContainer.layer.cornerRadius = 5
        attachmentPriceVCContainer.layer.cornerRadius = 10
        attachmentPriceVCContainer.layer.borderWidth = 1
        attachmentPriceVCContainer.layer.borderColor = UIColor.Sphinx.ReceivedBubbleBorder.resolvedCGColor(with: self.view)
        attachmentPriceVCContainer.clipsToBounds = true
    }
}
