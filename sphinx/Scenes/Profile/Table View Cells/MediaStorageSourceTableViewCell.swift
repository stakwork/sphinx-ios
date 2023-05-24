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
    @IBOutlet weak var squareImageView: UIImageView!
    @IBOutlet weak var disclosureImageView: UIImageView!
    @IBOutlet weak var deleteButton: UIButton!
    
    var index : Int? = nil
    var delegate: MediaStorageSourceTableViewCellDelegate? = nil
    
    static let reuseID = "MediaStorageSourceTableViewCell"

    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
    func configure(forSource:StorageManagerMediaSource){
        switch(forSource){
        case .chats:
            mediaSourceLabel.text = "Chats"
            break
        case .podcasts:
            mediaSourceLabel.text = "Podcasts"
            squareImageView.image = #imageLiteral(resourceName: "podcastTypeIcon")
            squareImageView.layer.cornerRadius = 6
            break
        }
    }
    
    func configure(forChat:Chat,items:[StorageManagerItem]){
        mediaSourceLabel.text = forChat.name
        mediaSourceSizeLabel.text = formatBytes(Int(StorageManager.sharedManager.getItemGroupTotalSize(items: items)))
        if let imageURL = URL(string: forChat.photoUrl ?? ""){
            squareImageView.sd_setImage(with: imageURL)
        }
        else{
            //TODO: show initials
        }
        squareImageView.layer.cornerRadius = 6
    }
    
    
    func configure(podcastFeed:PodcastFeed,items:[StorageManagerItem]){
        mediaSourceLabel.text = podcastFeed.title
        if let imageURL = URL(string: podcastFeed.imageToShow ?? ""){
            squareImageView.sd_setImage(with: imageURL)
        }
        squareImageView.layer.cornerRadius = 6
        mediaSourceSizeLabel.text = formatBytes(Int(StorageManager.sharedManager.getItemGroupTotalSize(items: items)*1e6))
    }
    
    func configure(podcastEpisode:PodcastEpisode,item:StorageManagerItem,index:Int){
        mediaSourceLabel.text = podcastEpisode.title
        if let imageURL = URL(string: podcastEpisode.imageToShow ?? ""){
            squareImageView.sd_setImage(with: imageURL)
        }
        squareImageView.layer.cornerRadius = 6
        mediaSourceSizeLabel.text = formatBytes(Int(StorageManager.sharedManager.getItemGroupTotalSize(items: [item])*1e6))
        
        self.index = index
        
        disclosureImageView.isHidden = true
        deleteButton.isHidden = false
    }
    
    
    @IBAction func deleteItemTapped(_ sender: Any) {
        if let index = index{
            delegate?.didTapItemDelete(index: index)
        }
    }
    
}
