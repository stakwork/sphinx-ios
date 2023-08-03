//
//  MessageBoostImageView.swift
//  sphinx
//
//  Created by Tomas Timinskas on 05/06/2023.
//  Copyright © 2023 sphinx. All rights reserved.
//

import UIKit
import SDWebImage

class MessageBoostImageView: UIView {
    
    @IBOutlet private var contentView: UIView!

    @IBOutlet weak var circularBorderView: UIView!
    @IBOutlet weak var initialsLabel: UILabel!
    @IBOutlet weak var circularView: UIView!
    @IBOutlet weak var imageView: UIImageView!
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setup()
    }

    private func setup() {
        Bundle.main.loadNibNamed("MessageBoostImageView", owner: self, options: nil)
        addSubview(contentView)
        contentView.frame = self.bounds
        contentView.autoresizingMask = [.flexibleHeight, .flexibleWidth]
        
        circularBorderView.layer.cornerRadius = circularBorderView.bounds.height / 2
        circularView.layer.cornerRadius = circularView.bounds.height / 2
        imageView.layer.cornerRadius = imageView.bounds.height / 2
    }
    
    func configureWith(
        boost: BubbleMessageLayoutState.Boost,
        and direction: MessageTableCellState.MessageDirection
    ) {
        let bubbleColor = direction.isOutgoing() ? UIColor.Sphinx.SentMsgBG : UIColor.Sphinx.ReceivedMsgBG
        circularBorderView.backgroundColor = bubbleColor
        
        circularView.backgroundColor = boost.senderColor ?? UIColor.Sphinx.SecondaryText
        initialsLabel.text = (boost.senderAlias ?? "Unknown").getInitialsFromName()
        
        imageView.isHidden = true
        imageView.sd_cancelCurrentImageLoad()
        
        if let senderPic = boost.senderPic, let url = URL(string: senderPic) {
            
            let transformer = SDImageResizingTransformer(
                size: CGSize(width: imageView.bounds.size.width * 3, height: imageView.bounds.size.height * 3),
                scaleMode: .aspectFill
            )
            
            imageView.sd_setImage(
                with: url,
                placeholderImage: UIImage(named: "profile_avatar"),
                options: [.scaleDownLargeImages, .decodeFirstFrameOnly, .lowPriority],
                context: [.imageTransformer: transformer],
                progress: nil,
                completed: { (image, error, _, _) in
                    if (error == nil) {
                        self.imageView.isHidden = false
                        self.imageView.image = image
                    }
                }
            )
        }
        
        self.isHidden = false
    }
}
