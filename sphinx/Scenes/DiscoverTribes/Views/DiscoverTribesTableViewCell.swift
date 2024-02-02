//
//  DiscoverTribesTableViewCell.swift
//  sphinx
//
//  Created by James Carucci on 1/4/23.
//  Copyright © 2023 sphinx. All rights reserved.
//

import UIKit

protocol DiscoverTribesCellDelegate{
    func handleJoin(url:URL)
}

class DiscoverTribesTableViewCell: UITableViewCell {
    
    
    @IBOutlet weak var tribeImageView: UIImageView!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var descriptionLabel: UILabel!
    @IBOutlet weak var joinButton: UIButton!
    var cellURL : URL? = nil
    var delegate : DiscoverTribesCellDelegate? = nil
    
    
    static let reuseID = "DiscoverTribesTableViewCell"
    
    static let nib: UINib = {
        UINib(nibName: "DiscoverTribesTableViewCell", bundle: nil)
    }()
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
    func configureCell(tribeData:DiscoverTribeData,wasJoined:Bool){
        if let urlString = tribeData.imgURL,
           let url = URL(string: urlString) {
            
            tribeImageView.sd_setImage(with: url, placeholderImage: UIImage(named: "tribePlaceholder"))
            tribeImageView.layer.cornerRadius = 24
            tribeImageView.clipsToBounds = true
        }
        else if tribeData.imgURL == nil{
            tribeImageView.sd_setImage(with: URL(string: ""), placeholderImage: UIImage(named: "tribePlaceholder"))
        }
        
        titleLabel.text = tribeData.name
        descriptionLabel.text = tribeData.description
        
        configureJoinButton(tribeData: tribeData,wasJoined:wasJoined)
        styleCell()
    }
    
    func styleCell(){
        self.tribeImageView.layer.cornerRadius = 6.0
        self.backgroundColor = UIColor.Sphinx.Body
        self.contentView.backgroundColor = UIColor.Sphinx.Body
        self.titleLabel.textColor = UIColor.Sphinx.PrimaryText
        self.descriptionLabel.textColor = UIColor.Sphinx.SecondaryText
    }
    
    func configureJoinButton(tribeData:DiscoverTribeData,wasJoined:Bool){
        joinButton.layer.cornerRadius = 15.0
        
        let host = tribeData.host ?? API.kTribesServerBaseURL.replacingOccurrences(of: "https://", with: "")
        
        if let pubkey = tribeData.pubkey{
            joinButton.isEnabled = true
            cellURL = URL(string: "sphinx.chat://?action=tribeV2&pubkey=\(pubkey)&host=34.229.52.200:8801")
            joinButton.addTarget(self, action: #selector(handleJoinTap), for: .touchUpInside)
        }
        else if let uuid = tribeData.uuid {
            joinButton.isEnabled = true
            cellURL = URL(string: "sphinx.chat://?action=tribe&uuid=\(uuid)&host=\(host)")
            joinButton.addTarget(self, action: #selector(handleJoinTap), for: .touchUpInside)
        } else {
            joinButton.isEnabled = false
        }
        
        if wasJoined {
            joinButton.backgroundColor = UIColor.Sphinx.ReceivedMsgBG
            joinButton.setTitle("open".localized, for: .normal)
            joinButton.setTitleColor(UIColor.Sphinx.BodyInverted, for: .normal)
        } else {
            joinButton.backgroundColor = UIColor.Sphinx.PrimaryBlue
            joinButton.setTitle("join".localized, for: .normal)
            joinButton.setTitleColor(UIColor.white, for: .normal)
        }
    }
    
    @objc func handleJoinTap(){
        if let valid_url = cellURL{
            self.delegate?.handleJoin(url: valid_url)
        }
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()

        tribeImageView.image = nil
        descriptionLabel.text = ""
        titleLabel.text = ""
    }
    
}
