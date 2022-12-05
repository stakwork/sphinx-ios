//
//  LinkPreviewView.swift
//  sphinx
//
//  Created by Tomas Timinskas on 05/03/2020.
//  Copyright © 2020 Sphinx. All rights reserved.
//

import UIKit
import MobileCoreServices
import SDWebImage
import SwiftLinkPreview
import LinkPresentation

class LinkPreviewView: UIView {
    
    @IBOutlet private var contentView: UIView!
    @IBOutlet weak var previewContainer: UIView!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var descriptionLabel: UILabel!
    @IBOutlet weak var iconImageView: UIImageView!
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var imageViewBack: UIView!
    @IBOutlet weak var loadingContainer: UIView!
    @IBOutlet weak var loadingWheel: UIActivityIndicatorView!
    @IBOutlet weak var loadingLabel: UILabel!
    @IBOutlet weak var imageWidthConstraint: NSLayoutConstraint!
    
    let kImageContainerWidth: CGFloat = 90
    
    var loading = false {
        didSet {
            loadingLabel.alpha = loading ? 1.0 : 0.0
            previewContainer.alpha = loading ? 0.0 : 1.0
            
            LoadingWheelHelper.toggleLoadingWheel(loading: loading, loadingWheel: loadingWheel, loadingWheelColor: UIColor.Sphinx.Text)
        }
    }
    
    var cancellableLP: Cancellable?
    var lpMetadataProvider: NSObject?
    var linkURLString: String!
    var slp = CustomSwiftLinkPreview.sharedInstance
    
    var messageId: Int = -1
    var doneCompletion: ((Int) -> ())? = nil
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setup()
    }
    
    override func removeFromSuperview() {
        super.removeFromSuperview()
        stopLoading()
    }

    private func setup() {
        Bundle.main.loadNibNamed("LinkPreviewView", owner: self, options: nil)
        addSubview(contentView)
        contentView.frame = self.bounds
        contentView.autoresizingMask = [.flexibleHeight, .flexibleWidth]
        
        let tap = UITapGestureRecognizer(target: self, action: #selector(linkButtonTouched))
        self.addGestureRecognizer(tap)
    }
    
    @objc func linkButtonTouched() {
        if let link = self.linkURLString {
            UIApplication.shared.open(URL(string: link)!, options: [:], completionHandler: nil)
        }
    }
    
    func getLinkURL(link: String) -> String {
        return slp.extractURL(text: link)?.absoluteString ?? ""
    }
    
    func configurePreview(messageRow: TransactionMessageRow, doneCompletion: ((Int) -> ())? = nil) {
        self.messageId = messageRow.transactionMessage?.id ?? -1
        self.doneCompletion = doneCompletion
        
        loadingLabel.text = "loading.preview".localized
        loading = true
        
        stopLoading()
        let link = messageRow.getMessageLink()
        linkURLString = getLinkURL(link: link)
        loadWithSwiftLinkPreview(link: linkURLString)
    }
    
    func loadWithSwiftLinkPreview(link: String) {
        if #available(iOS 13.0, *) {
            if let existingMetadata = MetaDataCache.retrieve(urlString: linkURLString) {
                previewLoadingSucceed(metadata: existingMetadata, link: link)
            } else {
                self.loadWithLinkPresentation(link: link)
            }
        } else {
            if let cached = slp.cache.slp_getCachedResponse(url: link) {
                self.previewLoadingSucceed(result: cached)
            } else  {
                cancellableLP = slp.preview(link, onSuccess: { result in
                    self.previewLoadingSucceed(result: result)
                }, onError: { error in
                    self.slp.cache.slp_setCachedResponse(url: self.linkURLString, response: Response())
                    self.previewLoadingFailed()
                })
            }
        }
    }
    
    @available(iOS 13.0, *)
    func loadWithLinkPresentation(link: String) {
        guard let url = URL(string: link) else {
            previewLoadingFailed()
            return
        }
        
        lpMetadataProvider = LPMetadataProvider()
        (lpMetadataProvider as? LPMetadataProvider)?.startFetchingMetadata(for: url) { metadata, error in
            DispatchQueue.main.async {
                guard let metadata = metadata, error == nil else {
                    self.previewLoadingFailed()
                    return
                }
                
                MetaDataCache.cache(metadata: metadata, link: link)
                self.previewLoadingSucceed(metadata: metadata, link: link)
            }
        }
    }
    
    @available(iOS 13.0, *)
    func previewLoadingSucceed(metadata: LPLinkMetadata, link: String) {
        let title = URL(string: link)?.domain?.capitalized ?? (metadata.url?.absoluteString ?? "")
        let description = (metadata.title ?? "").withDefaultValue("title.not.available".localized) + "\n\n" + (metadata.url?.absoluteString ?? "")
        titleLabel.text = title
        descriptionLabel.text = description
        
        resetImages()
        
        loading = false
        
        metadata.iconProvider?.loadItem(forTypeIdentifier: kUTTypeImage as String, options: nil) { (data, error) in
            guard let data = data as? Data else {
                return
            }
            if let image = UIImage(data: data) {
                DispatchQueue.main.async {
                    self.setImages(image: image, isIcon: true)
                }
            }
        }
        
        metadata.imageProvider?.loadItem(forTypeIdentifier: kUTTypeImage as String, options: nil) { (data, error) in
            guard let data = data as? Data else {
                return
            }
            if let image = UIImage(data: data) {
                DispatchQueue.main.async {
                    self.setImages(image: image, isIcon: false)
                }
            }
        }
        
        doneCompletion?(messageId)
    }
    
    func resetImages() {
        imageView.contentMode = .scaleAspectFit
        iconImageView.contentMode = .scaleAspectFit
        
        imageView.image = nil
        iconImageView.image = LinkPreviewUIImage(named: "imageNotAvailable")
    }
    
    func setImages(image: UIImage, isIcon: Bool) {
        if isIcon {
            iconImageView.image = image
            if imageView.image == nil { imageView.image = image }
        } else {
            imageView.image = image
            if (iconImageView.image as? LinkPreviewUIImage)?.imageName  == "imageNotAvailable" { iconImageView.image = image }
        }
    }
    
    func previewLoadingSucceed(result: Response) {
        guard let title = result.title else {
            previewLoadingFailed()
            return
        }
        resetImages()
        let description = result.description ?? ""
        
        handlePreviewImage(mainImage: result.image, images: result.images, icon: result.icon)
        titleLabel.text = title.withDefaultValue("title.not.available".localized)
        descriptionLabel.text = description.withDefaultValue("description.not.available".localized)
        
        doneCompletion?(messageId)
    }
    
    func handlePreviewImage(mainImage: String?, images: [String]?, icon: String?) {
        var imagesArray: [String] = []
        
        if let images = images {
            for i in images {
                imagesArray.append(i)
            }
        }
        
        if let image = mainImage {
            imagesArray.append(image)
        }
        
        loadPreviewImage(imagesArray: imagesArray, imageView: imageView, index: 0)
        
        if let icon = icon {
            loadPreviewImage(imagesArray: [icon], imageView: iconImageView, index: 0)
        } else {
            loadPreviewImage(imagesArray: imagesArray, imageView: iconImageView, index: 0)
        }
    }
    
    func loadPreviewImage(imagesArray: [String], imageView: UIImageView, index: Int) {
        if index >= imagesArray.count {
            imageLoadFailed()
            return
        }
        
        let imageURL = imagesArray[index]
        
        if imageURL.contains(".svg") {
            imageViewBack.backgroundColor = UIColor.Sphinx.Text
        } else {
            imageViewBack.backgroundColor = UIColor.clear
        }
        
        if let nsUrl = URL(string: imageURL), imageURL != "" {
            MediaLoader.asyncLoadImage(imageView: imageView, nsUrl: nsUrl, placeHolderImage: nil, completion: { image in
                MediaLoader.storeImageInCache(img: image, url: imageURL)
                self.showImage(image: image, imageView: imageView)
            }, errorCompletion: { error in
                self.loadPreviewImage(imagesArray: imagesArray, imageView: imageView, index: index + 1)
            })
        } else {
            self.loadPreviewImage(imagesArray: imagesArray, imageView: imageView, index: index + 1)
        }
    }
    
    func showImage(image: UIImage, imageView: UIImageView) {
        setImageContainerWidth(width: kImageContainerWidth)
        
        loading = false
        imageView.image = image
    }
    
    func imageLoadFailed() {
        setImageContainerWidth(width: 0)
        
        loading = false
        imageView.contentMode = .center
        
        imageView.image = UIImage(named: "imageNotAvailable")
        imageView.tintColor = UIColor.Sphinx.SecondaryText
        imageView.tintColorDidChange()
    }
    
    func setImageContainerWidth(width: CGFloat) {
        imageWidthConstraint.constant = width
        imageViewBack.superview?.layoutIfNeeded()
    }

    func previewLoadingFailed() {
        loading = false
        previewContainer.alpha = 0.0
        loadingLabel.text = "preview.not.available".localized
        loadingLabel.alpha = 1.0
    }
    
    func stopLoading() {
        cancellableLP?.cancel()
        
        if #available(iOS 13.0, *) {
            (lpMetadataProvider as? LPMetadataProvider)?.cancel()
        }
    }
    
    func addConstraintsTo(bubbleView: UIView, messageRow: TransactionMessageRow) {
        let isIncoming = messageRow.isIncoming()
        let paidReceivedItem = messageRow.shouldShowPaidAttachmentView()
        
        var bottomMargin: CGFloat = 0
        if paidReceivedItem { bottomMargin += PaidAttachmentView.kViewHeight }
        
        let leftMargin = isIncoming ? Constants.kBubbleReceivedArrowMargin : 0
        let rightMargin = isIncoming ? 0 : Constants.kBubbleSentArrowMargin
        
        self.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint(item: self, attribute: NSLayoutConstraint.Attribute.bottom, relatedBy: NSLayoutConstraint.Relation.equal, toItem: bubbleView, attribute: NSLayoutConstraint.Attribute.bottom, multiplier: 1.0, constant: -bottomMargin).isActive = true
        NSLayoutConstraint(item: self, attribute: NSLayoutConstraint.Attribute.leading, relatedBy: NSLayoutConstraint.Relation.equal, toItem: bubbleView, attribute: NSLayoutConstraint.Attribute.leading, multiplier: 1.0, constant: leftMargin).isActive = true
        NSLayoutConstraint(item: self, attribute: NSLayoutConstraint.Attribute.trailing, relatedBy: NSLayoutConstraint.Relation.equal, toItem: bubbleView, attribute: NSLayoutConstraint.Attribute.trailing, multiplier: 1.0, constant: -rightMargin).isActive = true
        NSLayoutConstraint(item: self, attribute: NSLayoutConstraint.Attribute.height, relatedBy: NSLayoutConstraint.Relation.equal, toItem: nil, attribute: NSLayoutConstraint.Attribute.notAnAttribute, multiplier: 1, constant: Constants.kLinkPreviewHeight).isActive = true
    }
}
