//
//  ChatImageCollectionViewCell.swift
//  sphinx
//
//  Created by James Carucci on 5/26/23.
//  Copyright © 2023 sphinx. All rights reserved.
//

import UIKit

class ChatImageCollectionViewCell: UICollectionViewCell {

    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var overlay: UIView!
    @IBOutlet weak var checkmarkView: UIView!
    @IBOutlet weak var sizeLabel: UILabel!
    
    
    static let reuseID = "ChatImageCollectionViewCell"
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    func configure(cachedMedia:CachedMedia,size:CGSize,selectionStatus:Bool,memorySizeMB:Double){
        if let image = cachedMedia.image{
            let resizedImage = image.resizeImage(newSize: size)
            imageView.image = resizedImage
            imageView.contentMode = .center
        }
        if(selectionStatus){
            overlay.backgroundColor = UIColor.Sphinx.Body
            overlay.alpha = 0.75
            overlay.isHidden = false
            checkmarkView.isHidden = false
            checkmarkView.makeCircular()
            sizeLabel.isHidden = true
        }
        else{
            overlay.backgroundColor = .clear
            overlay.isHidden =  true
            checkmarkView.isHidden = false
            sizeLabel.text = formatBytes(Int(1e6 * memorySizeMB))
            sizeLabel.isHidden = false
        }
    }
    
    override func prepareForReuse() {
        self.overlay.isHidden = true
        imageView.image = nil
    }
    
}
