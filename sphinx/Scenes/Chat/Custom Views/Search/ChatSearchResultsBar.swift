//
//  ChatSearchResultsBar.swift
//  sphinx
//
//  Created by Tomas Timinskas on 27/06/2023.
//  Copyright © 2023 sphinx. All rights reserved.
//

import UIKit

protocol ChatSearchResultsBarDelegate {
    func didTapNavigateArrowButton(button: ChatSearchResultsBar.NavigateArrowButton)
}

class ChatSearchResultsBar: UIView {
    
    var delegate: ChatSearchResultsBarDelegate?
    
    @IBOutlet var contentView: UIView!

    @IBOutlet weak var matchesCountLabel: UILabel!
    @IBOutlet weak var arrowUpButton: UIButton!
    @IBOutlet weak var arrowDownButton: UIButton!
    
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
    
    func configureWith(
        matchesCount: Int,
        matchIndex: Int
    ) {
        
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
