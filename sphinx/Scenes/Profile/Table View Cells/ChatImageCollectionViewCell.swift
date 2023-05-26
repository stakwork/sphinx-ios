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
    
    static let reuseID = "ChatImageCollectionViewCell"
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    func configure(cachedMedia:CachedMedia,size:CGSize,selectionStatus:Bool){
        if let image = cachedMedia.image{
            let resizedImage = image.resizeImage(newSize: size)
            imageView.image = resizedImage
            imageView.contentMode = .center
        }
        if(selectionStatus){
            overlay.backgroundColor = UIColor.Sphinx.Body
            overlay.alpha = 0.75
        }
        else{
            overlay.backgroundColor = .clear
        }
    }
    
}
