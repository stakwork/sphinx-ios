//
//  NewLinkPreviewView.swift
//  sphinx
//
//  Created by Tomas Timinskas on 05/06/2023.
//  Copyright © 2023 sphinx. All rights reserved.
//

import UIKit
import SDWebImage

class NewLinkPreviewView: UIView {
    
    weak var delegate: LinkPreviewDelegate?

    @IBOutlet private var contentView: UIView!
    
    @IBOutlet weak var iconImageView: UIImageView!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var descriptionLabel: UILabel!
    @IBOutlet weak var pictureImageView: UIImageView!
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setup()
    }

    private func setup() {
        Bundle.main.loadNibNamed("NewLinkPreviewView", owner: self, options: nil)
        addSubview(contentView)
        contentView.frame = self.bounds
        contentView.autoresizingMask = [.flexibleHeight, .flexibleWidth]
    }
    
    func configureWith(
        linkData: MessageTableCellState.LinkData,
        delegate: LinkPreviewDelegate?
    ) {
        self.delegate = delegate
        
        loadImageOn(
            imageView: iconImageView,
            urlString: linkData.icon ?? linkData.image
        )
        
        loadImageOn(
            imageView: pictureImageView,
            urlString: linkData.image ?? linkData.icon
        )
        
        titleLabel.text = linkData.title
        descriptionLabel.text = linkData.description
    }
    
    func loadImageOn(
        imageView: UIImageView,
        urlString: String?
    ) {
        imageView.sd_cancelCurrentImageLoad()
        imageView.contentMode = .scaleAspectFit
        
        if let urlString = urlString, let url = URL(string: urlString) {

            imageView.sd_setImage(
                with: url,
                placeholderImage: UIImage(named: "imageNotAvailable"),
                options: [.scaleDownLargeImages, .decodeFirstFrameOnly, .lowPriority],
                progress: nil,
                completed: { (image, error, _, _) in
                    imageView.image = (error == nil) ? image : UIImage(named: "imageNotAvailable")
                }
            )
        } else {
            imageView.image = UIImage(named: "imageNotAvailable")
        }
    }
    
    @IBAction func didTapButton() {
        delegate?.didTapOnWebLinkButton()
    }
    
}
