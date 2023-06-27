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
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
    func configureWith(mentionOrMacro:MentionOrMacroItem,delegate:ChatMentionAutocompleteDelegate?){
        self.delegate = delegate
        self.mentionTextField.text = mentionOrMacro.displayText
        self.alias = mentionOrMacro.displayText
        self.type = mentionOrMacro.type
        self.action = mentionOrMacro.action
        //self.view.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(handleClick)))
        
        mentionTextField.font = UIFont(name: "Roboto", size: mentionTextField.font?.pointSize ?? 14.0)
        mentionTextField.textColor = UIColor.Sphinx.SecondaryText
        
        self.transform = CGAffineTransform(scaleX: 1, y: -1)
        self.backgroundColor = UIColor.Sphinx.HeaderBG
        self.selectionStyle = .none
        
        if(mentionOrMacro.type == .macro){
            avatarImage.image = mentionOrMacro.image ?? #imageLiteral(resourceName: "appPinIcon")
        }
        else{
            avatarImage.layer.contentsGravity = .resizeAspectFill
            avatarImage.sd_setImage(with: mentionOrMacro.imageLink, placeholderImage: #imageLiteral(resourceName: "appPinIcon"), context: nil)
            avatarImage.makeCircular()
        }
        avatarImage.tintColor = UIColor.Sphinx.BodyInverted
        
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        avatarImage?.image = nil
        contentView.layer.backgroundColor = UIColor.clear.cgColor
    }
    
    @objc func handleClick(){
        if let valid_alias = alias, type == .mention{
            //self.delegate?.processAutocomplete(text: valid_alias + " ")
        }
        else if type == .macro,
        let action = action{
            print("MACRO")
            //self.delegate?.processGeneralPurposeMacro(action: action)
        }
    }
    
}
