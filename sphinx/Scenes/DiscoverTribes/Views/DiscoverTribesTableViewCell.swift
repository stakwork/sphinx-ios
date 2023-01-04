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
    
    func configureCell(tribeData:DiscoverTribeData){
        if let urlString = tribeData.imgURL,
           let url = URL(string: urlString){
            self.tribeImageView.sd_setImage(with: url)
        }
        
        titleLabel.text = tribeData.name
        descriptionLabel.text = tribeData.description
        
        configureJoinButton(tribeData: tribeData)
        styleCell()
    }
    
    func styleCell(){
        self.backgroundColor = UIColor.Sphinx.Body
        self.titleLabel.textColor = UIColor.Sphinx.PrimaryText
        self.descriptionLabel.textColor = UIColor.Sphinx.SecondaryText
    }
    
    func configureJoinButton(tribeData:DiscoverTribeData){
        joinButton.titleLabel?.textColor = .white
        joinButton.titleLabel?.font = UIFont(name: "Roboto-Bold", size: 14.0)
        let host = tribeData.host ?? "tribes.sphinx.chat"
        if let uuid = tribeData.uuid//,
        {
            joinButton.backgroundColor = UIColor.Sphinx.PrimaryBlue
            cellURL = URL(string: "sphinx.chat://?action=tribe&uuid=\(uuid)&host=\(host)")
            joinButton.addTarget(self, action: #selector(handleJoinTap), for: .touchUpInside)
        }
        else{
            joinButton.backgroundColor = UIColor.lightGray
            joinButton.isEnabled = false
        }
    }
    
    @objc func handleJoinTap(){
        if let valid_url = cellURL{
            self.delegate?.handleJoin(url: valid_url)
        }
    }
    
}
