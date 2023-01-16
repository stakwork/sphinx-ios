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
        
        titleLabel.text = tribeData.name
        descriptionLabel.text = tribeData.description
        
        configureJoinButton(tribeData: tribeData,wasJoined:wasJoined)
        styleCell()
    }
    
    func styleCell(){
        self.backgroundColor = UIColor.Sphinx.Body
        self.contentView.backgroundColor = UIColor.Sphinx.Body
        self.titleLabel.textColor = UIColor.Sphinx.PrimaryText
        self.descriptionLabel.textColor = UIColor.Sphinx.SecondaryText
    }
    
    func configureJoinButton(tribeData:DiscoverTribeData,wasJoined:Bool){
        joinButton.layer.cornerRadius = 15.0
        let host = tribeData.host ?? API.kTribesServerBaseURL.replacingOccurrences(of: "https://", with: "")
        if let uuid = tribeData.uuid {
            cellURL = URL(string: "sphinx.chat://?action=tribe&uuid=\(uuid)&host=\(host)")
            joinButton.addTarget(self, action: #selector(handleJoinTap), for: .touchUpInside)
        } else {
            //joinButton.backgroundColor = UIColor.lightGray
            joinButton.isEnabled = false
        }
        
        if wasJoined{
            let attributes: [NSAttributedString.Key: Any] = [
                .foregroundColor: UIColor.Sphinx.BodyInverted,
                .font: UIFont(name: "Roboto", size: 15.0)
            ]
            joinButton.backgroundColor = UIColor.Sphinx.ReceivedMsgBG
            let string = NSAttributedString(string: "Open",attributes: attributes)
            joinButton.setAttributedTitle(string, for: .normal)
        }
        else{
            let attributes: [NSAttributedString.Key: Any] = [
                .foregroundColor: UIColor.white,
                .font: UIFont(name: "Roboto", size: 15.0)
            ]
            let string = NSAttributedString(string: "Join",attributes: attributes)
            joinButton.setAttributedTitle(string, for: .normal)
            joinButton.backgroundColor = UIColor.Sphinx.PrimaryBlue
        }
    }
    
    @objc func handleJoinTap(){
        if let valid_url = cellURL{
            self.delegate?.handleJoin(url: valid_url)
        }
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        //joinButton.titleLabel?.textColor = .black
        //joinButton.setTitle("Join", for: .normal)
        tribeImageView.image = nil
        descriptionLabel.text = ""
        titleLabel.text = ""
    }
    
}
