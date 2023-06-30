//
//  ChatMentionAutocompleteTableViewCell.swift
//  sphinx
//
//  Created by James Carucci on 6/27/23.
//  Copyright © 2023 sphinx. All rights reserved.
//

import UIKit
import SDWebImage

class ChatMentionAutocompleteTableViewCell: UITableViewCell {
    
    @IBOutlet weak var mentionTextField: UITextField!
    @IBOutlet weak var dividerLine: UIView!
    @IBOutlet weak var avatarImage: UIImageView!
    @IBOutlet weak var iconLabel: UILabel!
    @IBOutlet weak var initialsView: UIView!
    @IBOutlet weak var initialsLabel: UILabel!
    
    static let reuseID = "ChatMentionAutocompleteTableViewCell"
    static let nib: UINib = {
        UINib(nibName: "ChatMentionAutocompleteTableViewCell", bundle: nil)
    }()
    
    var delegate : ChatMentionAutocompleteDelegate? = nil
    var alias : String? = nil
    var type : MentionOrMacroType = .mention
    var action: (()->())? = nil

    override func awakeFromNib() {
        super.awakeFromNib()
        
        self.transform = CGAffineTransform(scaleX: 1, y: -1)
        self.contentView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(handleClick)))
        
        avatarImage.makeCircular()
        initialsView.makeCircular()
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
    }
    
    func configureWith(mentionOrMacro: MentionOrMacroItem){
        self.alias = mentionOrMacro.displayText
        self.type = mentionOrMacro.type
        self.action = mentionOrMacro.action
        
        avatarImage.isHidden = true
        iconLabel.isHidden = true
        initialsView.isHidden = true
        
        mentionTextField.text = mentionOrMacro.displayText
        
        avatarImage?.sd_cancelCurrentImageLoad()
        
        if (mentionOrMacro.type == .macro) {
            
            if let icon = mentionOrMacro.icon {
                iconLabel.text = icon
                
                avatarImage.isHidden = true
                iconLabel.isHidden = false
            } else {
                avatarImage.image = mentionOrMacro.image ?? UIImage(named: "appPinIcon")
                avatarImage.contentMode = mentionOrMacro.imageContentMode ?? .center
                
                avatarImage.isHidden = false
                iconLabel.isHidden = true
            }
            
        } else {
            initialsView.isHidden = false
            initialsView.backgroundColor = UIColor.getColorFor(key: "\(mentionOrMacro.displayText)-color")
            initialsLabel.text = mentionOrMacro.displayText.getInitialsFromName()
            
            if let imageLink = mentionOrMacro.imageLink, let url = URL(string: imageLink) {
                avatarImage.sd_setImage(
                    with: url,
                    placeholderImage: UIImage(named: "profile_avatar"),
                    options: SDWebImageOptions.progressiveLoad,
                    completed: { (image, error, _, _) in
                        if let image = image {
                            self.avatarImage.image = image
                            self.avatarImage.isHidden = false
                        }
                    }
                )
            }
            
            avatarImage.contentMode = .scaleAspectFill
        }
        avatarImage.tintColor = UIColor.Sphinx.SecondaryText
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        
        avatarImage?.image = nil
        avatarImage?.sd_cancelCurrentImageLoad()
    }
    
    @objc func handleClick() {
        if let valid_alias = alias, type == .mention, let delegate = delegate {
            delegate.processAutocomplete(
                text: valid_alias
            )
        } else if type == .macro, let action = action {
            self.delegate?.processGeneralPurposeMacro(
                action: action
            )
        }
    }
    
}
