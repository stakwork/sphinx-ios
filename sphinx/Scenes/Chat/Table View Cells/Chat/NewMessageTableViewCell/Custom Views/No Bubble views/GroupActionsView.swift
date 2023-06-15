//
//  GroupActionsView.swift
//  sphinx
//
//  Created by Tomas Timinskas on 05/06/2023.
//  Copyright © 2023 sphinx. All rights reserved.
//

import UIKit

protocol GroupActionsViewDelegate: class {
    func didTapDeleteTribeButton()
    func didTapApproveRequestButton()
    func didTapRejectRequestButton()
}

class GroupActionsView: UIView {
    
    @IBOutlet private var contentView: UIView!
    
    @IBOutlet weak var groupActionMessageView: GroupActionMessageView!
    @IBOutlet weak var groupRemovedView: GroupRemovedView!
    @IBOutlet weak var groupRequestView: GroupRequestView!

    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setup()
    }

    private func setup() {
        Bundle.main.loadNibNamed("GroupActionsView", owner: self, options: nil)
        addSubview(contentView)
        contentView.frame = self.bounds
        contentView.autoresizingMask = [.flexibleHeight, .flexibleWidth]
    }
    
    func hideAllSubviews() {
        groupActionMessageView.isHidden = true
        groupRemovedView.isHidden = true
        groupRequestView.isHidden = true
    }
    
    func configureWith(
        groupMemberNotification: NoBubbleMessageLayoutState.GroupMemberNotification
    ) {
        hideAllSubviews()
        
        groupActionMessageView.configureWith(message: groupMemberNotification.message)
        groupActionMessageView.isHidden = false
    }
    
    func configureWith(
        groupKickRemovedOrDeclined: NoBubbleMessageLayoutState.GroupKickRemovedOrDeclined,
        andDelegate delegate: GroupActionsViewDelegate?
    ) {
        hideAllSubviews()
        
        groupRemovedView.configureWith(
            message: groupKickRemovedOrDeclined.message,
            andDelegate: delegate
        )
        groupRemovedView.isHidden = false
    }
    
    func configureWith(
        groupMemberRequest: NoBubbleMessageLayoutState.GroupMemberRequest,
        andDelegate delegate: GroupActionsViewDelegate?
    ) {
        hideAllSubviews()
        
        groupRequestView.configureWith(
            status: groupMemberRequest.status,
            isActiveMember: groupMemberRequest.isActiveMember,
            senderAlias: groupMemberRequest.senderAlias,
            andDelegate: delegate
        )
        groupRequestView.isHidden = false
    }

}
