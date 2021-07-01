//
//  Sphinx
//
//  Created by Tomas Timinskas on 08/04/2019.
//  Copyright © 2019 Sphinx. All rights reserved.
//

import UIKit

class AddContactTableViewCell: UITableViewCell {
    
    let rowHeight: CGFloat = 100
    
    weak var delegate: AddFriendRowButtonDelegate?

    @IBOutlet weak var topShadowView: UIView!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        let addFriendButtonView = AddFriendRowButton(frame: CGRect(x: 0.0, y: 0.0, width: WindowsManager.getWindowWidth(), height: rowHeight))
        addFriendButtonView.delegate = self
        if UserContact.getOwner()?.isVirtualNode() ?? false { addFriendButtonView.configureForAddFriend() }
        contentView.addSubview(addFriendButtonView)
        
        addTopShadow()
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
    }
    
    func addTopShadow() {
        topShadowView.layer.masksToBounds = false
        topShadowView.layer.shadowColor = UIColor.Sphinx.Shadow.resolvedCGColor(with: self)
        topShadowView.layer.shadowOffset = CGSize(width: 0, height: 3)
        topShadowView.layer.shadowOpacity = 0.2
        topShadowView.layer.shadowRadius = 3.0
    }
}

extension AddContactTableViewCell : AddFriendRowButtonDelegate {
    func didTouchAddFriend() {
        delegate?.didTouchAddFriend()
    }
    
    func didTouchCreateGroup() {
        delegate?.didTouchCreateGroup?()
    }
}
