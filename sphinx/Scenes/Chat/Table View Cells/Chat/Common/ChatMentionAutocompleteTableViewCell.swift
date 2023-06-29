//
//  ChatMentionAutocompleteTableViewCell.swift
//  sphinx
//
//  Created by James Carucci on 6/27/23.
//  Copyright © 2023 sphinx. All rights reserved.
//

import UIKit

class ChatMentionAutocompleteTableViewCell: UITableViewCell {
    
    @IBOutlet weak var mentionTextField: UITextField!
    @IBOutlet weak var dividerLine: UIView!
    @IBOutlet weak var avatarImage: UIImageView!
    @IBOutlet weak var iconLabel: UILabel!
    
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
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
    }
    
    func configureWith(mentionOrMacro: MentionOrMacroItem){
        self.alias = mentionOrMacro.displayText
        self.type = mentionOrMacro.type
        self.action = mentionOrMacro.action
        
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
            avatarImage.isHidden = false
            iconLabel.isHidden = true
            
            if let imageLink = mentionOrMacro.imageLink, let url = URL(string: imageLink) {
                avatarImage.sd_setImage(
                    with: url,
                    placeholderImage: UIImage(named: "profile_avatar"),
                    context: nil
                )
            } else {
                avatarImage.image = UIImage(named: "profile_avatar")
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
                text: valid_alias + " "
            )
        } else if type == .macro, let action = action {
            self.delegate?.processGeneralPurposeMacro(
                action: action
            )
        }
    }
    
}
