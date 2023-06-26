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
    @IBOutlet weak var labelContainerView: UIView!
    @IBOutlet weak var fileNameLabel: UILabel!
    @IBOutlet weak var fileNameLabelContainer: UIView!
    
    
    static let reuseID = "ChatImageCollectionViewCell"
    
    override func awakeFromNib() {
        super.awakeFromNib()
    }

    func configure(
        cachedMedia: CachedMedia,
        size: CGSize,
        selectionStatus: Bool,
        memorySizeMB: Double
    ){
        labelContainerView.layer.cornerRadius = labelContainerView.frame.height/2.0
        labelContainerView.alpha = 0.75
        if let image = cachedMedia.image {
            imageView.contentMode = .scaleAspectFill
            imageView.clipsToBounds = true
            imageView.image = image
        }
        else{
            let placeholderImage = cachedMedia.fileExtension == "mp3" ? #imageLiteral(resourceName:"musicTagIcon") :  #imageLiteral(resourceName:"fileOptionIcon")
            imageView.contentMode = .scaleAspectFill
            imageView.clipsToBounds = true
            imageView.image = placeholderImage
        }
        
        if(StorageManager.sharedManager.getStorageManagerTypeFromExtension(cm: cachedMedia) == .file
           && cachedMedia.fileExtension != "pdf"){
            //fileNameLabelContainer.isHidden = false
            print(cachedMedia.filePath)
            fileNameLabel.text = cachedMedia.filePath
        }
        
        if(selectionStatus){
            overlay.backgroundColor = UIColor.Sphinx.Body
            overlay.alpha = 0.75
            overlay.isHidden = false
            checkmarkView.isHidden = false
            checkmarkView.makeCircular()
            labelContainerView.isHidden = true
        }
        else{
            overlay.backgroundColor = .clear
            overlay.isHidden =  true
            checkmarkView.isHidden = false
            let mediaSizeText = formatBytes(Int(memorySizeMB * 1e6))
            sizeLabel.text = (mediaSizeText == "0 MB") ? "<1MB" : mediaSizeText
            labelContainerView.isHidden = false
        }
    }
    
    override func prepareForReuse() {
        self.overlay.isHidden = true
        imageView.image = nil
    }
    
}
