//
//  ChatAttachmentViewController+AnimatinsExtension.swift
//  sphinx
//
//  Created by Tomas Timinskas on 30/05/2023.
//  Copyright © 2023 sphinx. All rights reserved.
//

import UIKit

extension ChatAttachmentViewController {
    
    func animateView() {
        UIView.animate(withDuration: 0.1, animations: {
            self.view.alpha = 1.0
        }, completion: { _ in
            self.toggleOptionsContainer(show: true)
        })
    }
    
    func toggleOptionsContainer(
        show: Bool,
        withCompletion completion: (() -> ())? = nil
    ) {
        let finalBottomConstraint:CGFloat = show ? 0 : kOptionsBottomViewConstant
        
        if finalBottomConstraint == optionsContainerBottomConstraint.constant {
            dismissView(withCompletion: completion)
            return
        }
        
        optionsContainerBottomConstraint.constant = finalBottomConstraint
        
        UIView.animate(
            withDuration: 0.2,
            animations: {
                self.optionsContainer.superview?.layoutSubviews()
            },
            completion: { _ in
                completion?()
            }
        )
    }
    
    func hideOptionsContainer() {
        optionsContainerBottomConstraint.constant = kOptionsBottomViewConstant
        optionsContainer.superview?.layoutSubviews()
    }
    
    func dismissView(
        withCompletion completion: (() -> ())? = nil
    ) {
        previewVC?.removeProvisionalMessage()
        
        UIView.animate(
            withDuration: 0.2,
            animations: {
                self.view.alpha = 0.0
            },
            completion: { _ in
                if let completion = completion {
                    self.dismiss(animated: false, completion: {
                        completion()
                    })
                } else {
                    self.delegate?.willDismissPresentedVC()
                    self.dismiss(animated: false, completion: {})
                }
            })
    }
}
