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

    @IBOutlet weak var matchesCountLabel: UILabel!
    @IBOutlet weak var arrowUpButton: UIButton!
    @IBOutlet weak var arrowDownButton: UIButton!
    @IBOutlet weak var loadingWheel: UIActivityIndicatorView!
    
    public enum NavigateArrowButton: Int {
        case Up
        case Down
    }
    
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
        
        if let matchesCount = matchesCount {
            matchesCountLabel.text = matchesCount.searchMatchesString
        }
        
        let matchesC = matchesCount ?? 0
        
        arrowUpButton.isEnabled = matchesC > 0
        arrowUpButton.alpha = (matchesC > 0 && matchIndex < (matchesC - 1)) ? 1.0 : 0.5
        
        arrowDownButton.isEnabled = matchesC > 0
        arrowDownButton.alpha = (matchesC > 0 && matchIndex > 0) ? 1.0 : 0.5
        
        toggleLoadingWheel(active: loading)
    }

    @IBAction func navigateArrowButtonTouched(_ sender: UIButton) {
        switch(sender.tag) {
        case NavigateArrowButton.Up.rawValue:
            delegate?.didTapNavigateArrowButton(button: NavigateArrowButton.Up)
            break
        case NavigateArrowButton.Down.rawValue:
            delegate?.didTapNavigateArrowButton(button: NavigateArrowButton.Down)
            break
        default:
            break
        }
    }
}
