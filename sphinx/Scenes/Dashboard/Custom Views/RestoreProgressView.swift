//
//  RestoreProgressView.swift
//  sphinx
//
//  Created by Tomas Timinskas on 19/01/2022.
//  Copyright © 2022 sphinx. All rights reserved.
//

import UIKit

protocol RestoreProgressViewDelegate: class {
    func shouldFinishRestoring()
}

class RestoreProgressView: UIView {
    
    weak var delegate: RestoreProgressViewDelegate?
    
    @IBOutlet var contentView: UIView!
    @IBOutlet weak var restoreProgressView: UIView!
    @IBOutlet weak var restoreProgressLabel: UILabel!
    @IBOutlet weak var progressView: UIProgressView!
    @IBOutlet weak var finishRestoringButton: UIButton!
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setup()
    }
    
    private func setup() {
        Bundle.main.loadNibNamed("RestoreProgressView", owner: self, options: nil)
        addSubview(contentView)
        contentView.frame = self.bounds
        contentView.autoresizingMask = [.flexibleHeight, .flexibleWidth]
        
        restoreProgressView.layer.cornerRadius = 10
        restoreProgressView.clipsToBounds = true
        
        finishRestoringButton.layer.cornerRadius = finishRestoringButton.frame.height / 2
        finishRestoringButton.addShadow(location: .bottom, opacity: 0.3, radius: 5)
    }
    
    func showRestoreProgressView(
        with progress: Int,
        label: String,
        buttonEnabled: Bool
    ) {
        restoreProgressLabel.text = (progress == 0) ? "resume-restoring".localized : "\(label) \(progress)%"
        progressView.progress = Float(progress) / 100
        
        finishRestoringButton.isEnabled = buttonEnabled
        finishRestoringButton.alpha = buttonEnabled ? 1.0 : 0.5
        
        showViewAnimated()
    }
    
    func showViewAnimated() {
        if (!isHidden) {
            return
        }
        
        isHidden = false
        
        UIView.animate(withDuration: 0.3, animations: {
            self.alpha = 1.0
        })
    }
    
    func hideViewAnimated() {
        UIView.animate(withDuration: 0.3, animations: {
            self.alpha = 0.0
        }, completion: { _ in
            self.isHidden = true
        })
    }

    @IBAction func finishRestoringButtonTouched() {
        delegate?.shouldFinishRestoring()
        hideViewAnimated()
    }
}
