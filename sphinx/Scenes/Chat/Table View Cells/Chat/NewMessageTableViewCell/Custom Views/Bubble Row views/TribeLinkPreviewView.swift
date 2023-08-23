//
//  TribeLinkPreviewView.swift
//  sphinx
//
//  Created by Tomas Timinskas on 03/12/2020.
//  Copyright © 2020 Sphinx. All rights reserved.
//

import UIKit
import SDWebImage

protocol LinkPreviewDelegate: class {
    func didTapOnTribeButton()
    func didTapOnContactButton()
    func didTapOnWebLinkButton()
}

class TribeLinkPreviewView: UIView {
    
    weak var delegate: LinkPreviewDelegate?
    
    @IBOutlet private var contentView: UIView!
    @IBOutlet weak var tribeImageView: UIImageView!
    @IBOutlet weak var tribeNameLabel: UILabel!
    @IBOutlet weak var tribeDescriptionTextView: UITextView!
    @IBOutlet weak var containerButton: UIButton!
    @IBOutlet weak var tribeButtonContainer: UIView!
    @IBOutlet weak var tribeButtonView: UIView!
    @IBOutlet weak var borderView: UIView!
    
    let kDashedLayerName = "dashed-layer"
    let kNewTribeBubbleHeight: CGFloat = 165
    
    var messageId: Int = -1
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setup()
    }

    private func setup() {
        Bundle.main.loadNibNamed("TribeLinkPreviewView", owner: self, options: nil)
        addSubview(contentView)
        contentView.frame = self.bounds
        contentView.autoresizingMask = [.flexibleHeight, .flexibleWidth]
        
        tribeDescriptionTextView.textContainer.lineFragmentPadding = 0
        tribeDescriptionTextView.textContainerInset = .zero
        tribeDescriptionTextView.contentInset = .zero
        tribeDescriptionTextView.clipsToBounds = true
        
        tribeButtonView.layer.cornerRadius = 3
        
        tribeImageView.layer.cornerRadius = 3
        tribeImageView.clipsToBounds = true
        tribeImageView.layer.borderWidth = 1
        tribeImageView.layer.borderColor = UIColor.Sphinx.SecondaryText.withAlphaComponent(0.5).resolvedCGColor(with: self)
    }
    
    func configureWith(
        tribeData: MessageTableCellState.TribeData,
        and bubble: BubbleMessageLayoutState.Bubble,
        delegate: LinkPreviewDelegate?
    ) {
        self.delegate = delegate
        
        configureColors(incoming: bubble.direction.isIncoming())
        
        tribeButtonContainer.isHidden = !tribeData.showJoinButton
        contentView.backgroundColor = tribeData.showJoinButton ? UIColor.Sphinx.Body : UIColor.clear
        
        tribeNameLabel.text = tribeData.name
        tribeDescriptionTextView.text = tribeData.description

        loadImage(imageUrl: tribeData.imageUrl)
        
        borderView.removeDashedLineBorderWith(name: kDashedLayerName)
        
        if tribeData.showJoinButton {
            borderView.addDashedLineBorder(
                color: bubble.direction.isIncoming() ? UIColor.Sphinx.ReceivedMsgBG : UIColor.Sphinx.SentMsgBG,
                rect: CGRect(
                    x: 0,
                    y: 0,
                    width: tribeData.bubbleWidth,
                    height: kNewTribeBubbleHeight
                ),
                roundedBottom: true,
                roundedTop: false,
                name: kDashedLayerName
            )
        }
    }
    
    func configureColors(incoming: Bool) {
        let color = incoming ? UIColor.Sphinx.SecondaryText : UIColor.Sphinx.SecondaryTextSent
        tribeDescriptionTextView.textColor = color
        tribeImageView.tintColor = color
        tribeImageView.layer.borderColor = color.resolvedCGColor(with: self)
        
        let buttonColor = incoming ? UIColor.Sphinx.LinkReceivedButtonColor : UIColor.Sphinx.LinkSentButtonColor
        tribeButtonView.backgroundColor = buttonColor
    }
    
    func loadImage(imageUrl: String?) {
        tribeImageView.sd_cancelCurrentImageLoad()
        
        if let image = imageUrl, let url = URL(string: image) {
            let transformer = SDImageResizingTransformer(
                size: CGSize(width: tribeImageView.bounds.size.width * 3, height: tribeImageView.bounds.size.height * 3),
                scaleMode: .aspectFill
            )
            
            tribeImageView.sd_setImage(
                with: url,
                placeholderImage: UIImage(named: "tribePlaceholder"),
                options: [.scaleDownLargeImages, .decodeFirstFrameOnly, .lowPriority],
                context: [.imageTransformer: transformer],
                progress: nil,
                completed: { (image, error, _, _) in
                    self.tribeImageView.image = (error == nil) ? image : UIImage(named: "tribePlaceholder")
                }
            )
        } else {
            tribeImageView.image = UIImage(named: "tribePlaceholder")
        }
    }
    
    @IBAction func seeTribeButtonTouched() {
        delegate?.didTapOnTribeButton()
    }
}
