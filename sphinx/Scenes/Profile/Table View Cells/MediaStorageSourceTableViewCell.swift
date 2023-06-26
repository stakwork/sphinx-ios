//
//  MediaStorageSourceTableViewCell.swift
//  sphinx
//
//  Created by James Carucci on 5/23/23.
//  Copyright © 2023 sphinx. All rights reserved.
//

import UIKit

protocol MediaStorageSourceTableViewCellDelegate{
    func didTapItemDelete(index:Int)
}

class MediaStorageSourceTableViewCell: UITableViewCell {
    
    @IBOutlet weak var mediaSourceLabel: UILabel!
    @IBOutlet weak var mediaSourceSizeLabel: UILabel!
    @IBOutlet weak var initialsLabel: UILabel!
    @IBOutlet weak var squareImageView: UIImageView!
    @IBOutlet weak var disclosureImageView: UIImageView!
    @IBOutlet weak var deleteButton: UIButton!
    
    @IBOutlet weak var fileTypeLabel: UILabel!
    @IBOutlet weak var fileTypeView: UIView!
    
    @IBOutlet weak var blueCheckmarkImageView: UIImageView!
    
    
    var index : Int? = nil
    var delegate: MediaStorageSourceTableViewCellDelegate? = nil
    
    static let reuseID = "MediaStorageSourceTableViewCell"

    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        deleteButton.imageView?.contentMode = .scaleAspectFit
    }
    
    enum DocsColors {
        case red
        case green
        case blue
        case yellow
        
        var uiColor: UIColor {
            switch self {
            case .red:
                return UIColor(hex: "#D84535")
            case .green:
                return UIColor(hex: "#49C998")
            case .blue:
                return UIColor(hex: "#618AFF")
            case .yellow:
                return UIColor(hex: "#D6AD31")
            }
        }
    }
    
    func assignFileTypeColor(fileType:String)->UIColor{
        switch(fileType.lowercased()){
        case "pdf":
            return DocsColors.red.uiColor
        case "doc":
            return DocsColors.blue.uiColor
        case "xls":
            return DocsColors.green.uiColor
        case "wav", "mp3":
            return DocsColors.yellow.uiColor
        default:
            return UIColor.purple
        }
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
    override func prepareForReuse() {
        self.mediaSourceLabel.text = ""
        self.mediaSourceSizeLabel.text = ""
        self.squareImageView.image = nil
        self.blueCheckmarkImageView.isHidden = true
    }
    
    func configure(forSource:StorageManagerMediaSource){
        switch(forSource){
        case .chats:
            mediaSourceLabel.text = "Chats"
            squareImageView.image = #imageLiteral(resourceName: "appPinIcon")
            squareImageView.isHidden = false
            initialsLabel.isHidden = true
            squareImageView.makeCircular()
            break
        case .podcasts:
            mediaSourceLabel.text = "Podcasts"
            squareImageView.image = #imageLiteral(resourceName: "podcastTypeIcon")
            squareImageView.layer.cornerRadius = 6
            break
        }
    }
    
    func configure(forChat:Chat,items:[StorageManagerItem]){
        
        let name = forChat.getName()
        mediaSourceLabel.text = name
        
        
        mediaSourceSizeLabel.text = formatBytes(Int(StorageManager.sharedManager.getItemGroupTotalSize(items: items)))

        if let stringURL = forChat.getPhotoUrl(),
           let imageURL = URL(string:  stringURL){
            print(name)
            squareImageView.sd_setImage(with: imageURL)
            initialsLabel.isHidden = true
        }
        else{
            let name = name
            let color = UIColor.getColorFor(key: name)
            initialsLabel.textAlignment = .center
            initialsLabel.makeCircular()
            squareImageView.isHidden = true
            initialsLabel.isHidden = false
            initialsLabel.backgroundColor = color
            initialsLabel.textColor = UIColor.white
            initialsLabel.text = name.getInitialsFromName()
        }
        squareImageView.makeCircular()
        let mediaSizeText = formatBytes(Int(StorageManager.sharedManager.getItemGroupTotalSize(items: items)*1e6))
        mediaSourceSizeLabel.text = (mediaSizeText == "0 MB") ? "<1MB" : mediaSizeText
    }
    
    
    func configure(podcastFeed:PodcastFeed,items:[StorageManagerItem]){
        mediaSourceLabel.text = podcastFeed.title
        if let imageURL = URL(string: podcastFeed.imageToShow ?? ""){
            squareImageView.sd_setImage(with: imageURL)
        }
        squareImageView.layer.cornerRadius = 6
        let mediaSizeText = formatBytes(Int(StorageManager.sharedManager.getItemGroupTotalSize(items: items)*1e6))
        mediaSourceSizeLabel.text = (mediaSizeText == "0 MB") ? "<1MB" : mediaSizeText
    }
    
    func configure(podcastEpisode:PodcastEpisode,item:StorageManagerItem,index:Int,isSelected:Bool){
        mediaSourceLabel.text = podcastEpisode.title
        initialsLabel.isHidden = true
        if let imageURL = URL(string: podcastEpisode.imageToShow ?? podcastEpisode.feed?.imageToShow ?? ""){
            squareImageView.sd_setImage(with: imageURL)
        }
        else{
            squareImageView.image = #imageLiteral(resourceName: "podcastTypeIcon")
        }
        
        squareImageView.layer.cornerRadius = 6
        mediaSourceSizeLabel.text = formatBytes(Int(StorageManager.sharedManager.getItemGroupTotalSize(items: [item])*1e6))
        
        self.index = index
        
        disclosureImageView.isHidden = true
        deleteButton.isHidden = false
        
        blueCheckmarkImageView.isHidden = !isSelected
        squareImageView.isHidden = isSelected
    }
    
    func configure(fileName:String,fileType:String,item:StorageManagerItem,index:Int,isSelected:Bool){
        initialsLabel.isHidden = true
        mediaSourceLabel.text = fileName
        mediaSourceSizeLabel.text = formatBytes(Int(StorageManager.sharedManager.getItemGroupTotalSize(items: [item])*1e6))
        
        disclosureImageView.isHidden = true
        deleteButton.isHidden = false
        
        let displayType = fileType.uppercased()
        fileTypeLabel.text = (displayType != "OTHER") ? (displayType) : "?"
        fileTypeView.backgroundColor = assignFileTypeColor(fileType: fileType)
        fileTypeView.isHidden = false
        fileTypeView.layer.cornerRadius = 3.0
        
        self.index = index
        blueCheckmarkImageView.isHidden = !isSelected
        fileTypeView.isHidden = isSelected
    }
    
    
    @IBAction func deleteItemTapped(_ sender: Any) {
        if let index = index{
            delegate?.didTapItemDelete(index: index)
        }
    }
    
}
