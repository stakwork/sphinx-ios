//
//  AddedTagsView.swift
//  sphinx
//
//  Created by Oko-osi Korede on 26/03/2024.
//  Copyright © 2024 sphinx. All rights reserved.
//

import UIKit

protocol AddedTagsViewDelegate: class {
    func didTapCloseButton()
}

class AddedTagsView: UIView {
    
    weak var delegate: AddedTagsViewDelegate?
    
    @IBOutlet var contentView: UIView!
    
    @IBOutlet weak var container: UIView!
    @IBOutlet weak var tagLabel: UILabel!
    
    public static let kLeftMargin:CGFloat = 16
    public static let kRightMargin:CGFloat = 42
    
    public static let kDescriptionFont = UIFont(name: "Roboto-Regular", size: 14.0)!

    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setup()
    }
    
    private func setup() {
        Bundle.main.loadNibNamed("AddedTagsView", owner: self, options: nil)
        addSubview(contentView)
        contentView.frame = self.bounds
        contentView.autoresizingMask = [.flexibleHeight, .flexibleWidth]

        container.layer.cornerRadius = container.frame.size.height / 2
    }
    
    func configureWith(
        tag: GroupsManager.Tag,
        delegate: AddedTagsViewDelegate?
    ) {
        self.delegate = delegate
        
        tagLabel.text = tag.description
    }
    
    public static func getWidthWith(description: String) -> CGFloat {
        return kDescriptionFont.sizeOfString(
            description,
            constrainedToWidth: .greatestFiniteMagnitude
        ).width + kRightMargin + kLeftMargin
    }
    
    @IBAction func closeButtonTapped() {
        self.delegate?.didTapCloseButton()
    }
}
