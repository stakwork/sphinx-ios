//
//  FullScreenImageView.swift
//  sphinx
//
//  Created by Tomas Timinskas on 29/11/2019.
//  Copyright © 2019 Sphinx. All rights reserved.
//

import UIKit
import SDWebImageFLPlugin

class FullScreenImageView: UIView {
    
    @IBOutlet private var contentView: UIView!
    @IBOutlet weak var imageScrollView: CustomImageScrollView!
    @IBOutlet weak var loadingWheel: UIActivityIndicatorView!
    
    var pictureImageView: UIImageView = UIImageView()
    
    var loading = false {
        didSet {
            pictureImageView.alpha = loading ? 0.0 : 1.0
            imageScrollView.alpha = loading ? 0.0 : 1.0
            
            LoadingWheelHelper.toggleLoadingWheel(loading: loading, loadingWheel: loadingWheel, loadingWheelColor: UIColor.white)
        }
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setup()
    }

    private func setup() {
        Bundle.main.loadNibNamed("FullScreenImageView", owner: self, options: nil)
        addSubview(contentView)
        contentView.frame = self.bounds
        contentView.autoresizingMask = [.flexibleHeight, .flexibleWidth]
    }
    
    func configureImageScrollView() {
        imageScrollView.translatesAutoresizingMaskIntoConstraints = false
        let widthConstraint  = NSLayoutConstraint(item: imageScrollView, attribute: NSLayoutConstraint.Attribute.width, relatedBy: NSLayoutConstraint.Relation.equal, toItem: imageScrollView.superview, attribute: NSLayoutConstraint.Attribute.width, multiplier: 1, constant: 0)
        let heightConstraint = NSLayoutConstraint(item: imageScrollView, attribute: NSLayoutConstraint.Attribute.height, relatedBy:NSLayoutConstraint.Relation.equal, toItem: imageScrollView.superview, attribute: NSLayoutConstraint.Attribute.height, multiplier: 1, constant: 0)
        imageScrollView.superview?.addConstraints([widthConstraint, heightConstraint])
        imageScrollView.imageContentMode = .aspectFit
        imageScrollView.initialOffset = .center
        imageScrollView.setup()
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
    }
    
    func showWebViewImage(url:URL){
        loading = true
        pictureImageView.image = nil
        contentView.isHidden = false
        isHidden = false
        
        self.loadImage(webViewImageURL: url)
    }
    
    func showImage(message: TransactionMessage) {
        loading = true
        pictureImageView.image = nil
        contentView.isHidden = false
        isHidden = false
        
        UIView.animate(withDuration: 0.2, animations: {
            self.contentView.alpha = 1.0
            self.alpha = 1.0
        }, completion: { _ in
            self.loadImage(message: message)
        })
    }
    
    func hideImage() {
        if contentView.isHidden {
            return
        }
        
        UIView.animate(withDuration: 0.2, animations: {
            self.contentView.alpha = 0.0
            self.alpha = 0.0
        }, completion: { _ in
            self.contentView.isHidden = true
            self.alpha = 0.0
        })
    }
    
    func loadImage(webViewImageURL: URL) {
        URLSession.shared.dataTask(with: webViewImageURL) { data, response, error in
            if let data = data, let image = UIImage(data: data) {
                DispatchQueue.main.async { [self] in
                    // Test displaying image with a simple UIImageView
                    let webImageView = UIImageView(image: image)
                    webImageView.frame = self.bounds // Adjust frame as necessary
                    webImageView.contentMode = .scaleAspectFit
                    self.addSubview(webImageView)
                }
            } else if let error = error {
                print("Error loading image: \(error)")
            }
        }.resume()
    }
    
    func loadImage(message: TransactionMessage?) {
        if message?.isGiphy() ?? false {
            loadGifhy(message: message)
            return
        }
        
        guard let _: String = UserDefaults.Keys.attachmentsToken.get() else {
            AttachmentsManager.sharedInstance.authenticate(completion: { token in
                self.loadImage(message: message)
            }, errorCompletion: {
                self.hideImage()
            })
            return
        }
        
        guard let message = message else {
            return
        }
        
        if let nsUrl = message.getPurchaseAcceptItem()?.getMediaUrlFromMediaToken() ?? message.getMediaUrlFromMediaToken() {
            if message.isGif() {
                if let cachedGif = MediaLoader.getMediaDataFromCachedUrl(url:nsUrl.absoluteString) {
                    if let animated = SDAnimatedImage(data: cachedGif) {
                        self.imageScrollView.display(gif: animated)
                        self.loading = false
                    }
                }
            } else if let cachedImage = MediaLoader.getImageFromCachedUrl(url: nsUrl.absoluteString) {
                self.imageScrollView.display(image: cachedImage)
                self.loading = false
            } else {
                MediaLoader.loadDataFrom(URL: nsUrl, completion: { (data, _) in
                    DispatchQueue.main.async {
                        if let image = UIImage(data: data) {
                            self.imageScrollView.display(image: image)
                        }
                        self.loading = false
                    }
                }, errorCompletion: {
                    self.loading = false
                })
            }
        }
    }
    
    func loadGifhy(message: TransactionMessage?) {
        guard let message = message else {
            return
        }
        
        let messageContent = message.messageContent ?? ""
        if let url = GiphyHelper.getUrlFrom(message: messageContent, mobile: false) {
            GiphyHelper.getGiphyDataFrom(url: url, messageId: message.id, completion: { (data, messageId) in
                self.loading = false
                
                if let data = data, let img = UIImage.sd_image(withGIFData: data) {
                    self.imageScrollView.display(image: img)
                } else {
                    self.hideImage()
                }
            })
            return
        }
        
        self.hideImage()
    }
}
