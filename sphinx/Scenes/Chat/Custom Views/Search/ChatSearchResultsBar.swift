//
//  ChatSearchResultsBar.swift
//  sphinx
//
//  Created by Tomas Timinskas on 27/06/2023.
//  Copyright © 2023 sphinx. All rights reserved.
//

import UIKit

protocol ChatSearchResultsBarDelegate : class {
    func didTapNavigateArrowButton(button: ChatSearchResultsBar.NavigateArrowButton)
}

class ChatSearchResultsBar: UIView {
    
    var delegate: ChatSearchResultsBarDelegate?
    
    @IBOutlet var contentView: UIView!

    @IBOutlet weak var matchIndexLabel: UILabel!
    @IBOutlet weak var matchesCountLabel: UILabel!
    @IBOutlet weak var arrowUpButton: UIButton!
    @IBOutlet weak var arrowDownButton: UIButton!
    @IBOutlet weak var loadingWheel: UIActivityIndicatorView!
    
    public enum NavigateArrowButton: Int {
        case Up
        case Down
    }
    
    var matchesCount: Int = 0
    var matchIndex: Int = 0
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setup()
    }
    
    private func setup() {
        Bundle.main.loadNibNamed("ChatSearchResultsBar", owner: self, options: nil)
        addSubview(contentView)
        
        contentView.frame = self.bounds
        contentView.autoresizingMask = [.flexibleHeight, .flexibleWidth]
        self.autoresizingMask = [.flexibleHeight, .flexibleWidth]
    }
    
    func toggleLoadingWheel(
        active: Bool
    ) {
        loadingWheel.isHidden = !active
        
        if active {
            loadingWheel.startAnimating()
        } else {
            loadingWheel.stopAnimating()
        }
    }
    
    func configureWith(
        matchesCount: Int? = nil,
        matchIndex: Int,
        loading: Bool,
        delegate: ChatSearchResultsBarDelegate?
    ) {
        self.delegate = delegate
        self.matchesCount = matchesCount ?? 0
        self.matchIndex = matchIndex
        
        configureArrowsWith(
            matchesCount: matchesCount ?? 0,
            matchIndex: matchIndex
        )
        
        toggleLoadingWheel(active: loading)
    }
    
    func configureArrowsWith(
        matchesCount: Int,
        matchIndex: Int
    ) {
        matchIndexLabel.isHidden = matchesCount <= 0
        matchIndexLabel.text = "\(matchIndex+1)\\"
        matchesCountLabel.text = matchesCount.searchMatchesString
        
        arrowUpButton.isEnabled = (matchesCount > 0 && matchIndex < (matchesCount - 1))
        arrowUpButton.alpha = (matchesCount > 0 && matchIndex < (matchesCount - 1)) ? 1.0 : 0.3
        
        arrowDownButton.isEnabled = (matchesCount > 0 && matchIndex > 0)
        arrowDownButton.alpha = (matchesCount > 0 && matchIndex > 0) ? 1.0 : 0.3
    }

    @IBAction func navigateArrowButtonTouched(_ sender: UIButton) {
        sender.isUserInteractionEnabled = false
        
        switch(sender.tag) {
        case NavigateArrowButton.Up.rawValue:
            matchIndex = matchIndex + 1
            
            configureArrowsWith(
                matchesCount: matchesCount,
                matchIndex: matchIndex
            )
            
            delegate?.didTapNavigateArrowButton(button: NavigateArrowButton.Up)
        case NavigateArrowButton.Down.rawValue:
            matchIndex = matchIndex - 1
            
            configureArrowsWith(
                matchesCount: matchesCount,
                matchIndex: matchIndex
            )
            
            delegate?.didTapNavigateArrowButton(button: NavigateArrowButton.Down)
        default:
            break
        }
        
        DelayPerformedHelper.performAfterDelay(seconds: 0.5, completion: {
            sender.isUserInteractionEnabled = true
        })
    }
}
