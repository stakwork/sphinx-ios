//
//  UIView + Constraints.swift
//  sphinx
//
//  Created by Oko-osi Korede on 22/03/2024.
//  Copyright © 2024 sphinx. All rights reserved.
//

import UIKit

extension UIView {
    func anchor(top: NSLayoutYAxisAnchor? = nil,
                trailing: NSLayoutXAxisAnchor? = nil,
                bottom: NSLayoutYAxisAnchor? = nil,
                leading: NSLayoutXAxisAnchor? = nil,
                topPadding: CGFloat = 0,
                trailingPadding: CGFloat = 0,
                bottomPadding: CGFloat = 0,
                leadingPadding: CGFloat = 0,
                width: CGFloat? = nil,
                height: CGFloat? = nil
    ) {
        translatesAutoresizingMaskIntoConstraints = false
        if let top {
            self.topAnchor.constraint(equalTo: top, constant: topPadding).isActive = true
        }
        if let trailing {
            self.trailingAnchor.constraint(equalTo: trailing, constant: trailingPadding).isActive = true
        }
        if let bottom {
            self.bottomAnchor.constraint(equalTo: bottom, constant: bottomPadding).isActive = true
        }
        if let leading {
            self.leadingAnchor.constraint(equalTo: leading, constant: leadingPadding).isActive = true
        }
        if let width {
            self.widthAnchor.constraint(equalToConstant: width).isActive = true
        }
        if let height {
            self.heightAnchor.constraint(equalToConstant: height).isActive = true
        }
    }
    
    func addSubview(_ views: [UIView]) {
        views.forEach { view in
            self.addSubview(view)
        }
    }
    
    func center(in view: UIView, axis: UIAxis) {
        translatesAutoresizingMaskIntoConstraints = false
        if axis == .horizontal {
            self.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
        }
        if axis == .vertical {
            self.centerYAnchor.constraint(equalTo: view.centerYAnchor).isActive = true
        }
        if axis == .both {
            self.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
            self.centerYAnchor.constraint(equalTo: view.centerYAnchor).isActive = true
        }
    }
}
