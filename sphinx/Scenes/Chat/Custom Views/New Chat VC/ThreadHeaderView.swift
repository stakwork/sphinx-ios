//
//  ThreadHeaderView.swift
//  sphinx
//
//  Created by James Carucci on 7/19/23.
//  Copyright © 2023 sphinx. All rights reserved.
//

import Foundation
import UIKit


class ThreadHeaderView : UIView{
    
    @IBOutlet var contentView: UIView!
    @IBOutlet weak var firstMessageMessageContentLabel: UILabel!
    @IBOutlet weak var avatarImageView: UIImageView!
    
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setup()
    }
    
    private func setup() {
        Bundle.main.loadNibNamed("ThreadHeaderView", owner: self, options: nil)
        addSubview(contentView)
        
        contentView.frame = self.bounds
        contentView.autoresizingMask = [.flexibleHeight, .flexibleWidth]
        
        autoresizingMask = [.flexibleHeight, .flexibleWidth]
    }
    
    func configureWith(message:TransactionMessage){
        firstMessageMessageContentLabel.text = message.messageContent
        avatarImageView.sd_setImage(with: URL(string: message.senderPic ?? ""))
        avatarImageView.makeCircular()
    }
    
}
