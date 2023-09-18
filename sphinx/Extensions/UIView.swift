//
//  UIView.swift
//  sphinx
//
//  Created by Tomas Timinskas on 12/09/2019.
//  Copyright © 2019 Sphinx. All rights reserved.
//

import UIKit

enum VerticalLocation: String {
    case bottom
    case top
    case bottomLeft
    case center
}

extension UIView {
    var isVisible : Bool {
        return !self.isHidden && self.alpha == 1.0
    }
    
    public func orientationHasChanged(_ isInPortrait:inout Bool) -> Bool {
        if self.frame.width > self.frame.height {
            if isInPortrait {
                isInPortrait = false
                return true
            }
        } else {
            if !isInPortrait {
                isInPortrait = true
                return true
            }
        }
        return false
    }
    
    var globalPoint :CGPoint? {
        return self.superview?.convert(self.frame.origin, to: nil)
    }

    var globalFrame :CGRect? {
        return self.superview?.convert(self.frame, to: nil)
    }
    
    func getVerticalDottedLine(color: UIColor = UIColor.white, frame: CGRect) -> CAShapeLayer {
        let cgColor = color.resolvedCGColor(with: self)

        let shapeLayer: CAShapeLayer = CAShapeLayer()
        shapeLayer.frame = CGRect(x: frame.origin.x + 0.5, y: frame.origin.y, width: 1.5, height: frame.height)
        shapeLayer.fillColor = cgColor
        shapeLayer.strokeColor = cgColor
        shapeLayer.lineWidth = 1.5
        shapeLayer.lineDashPattern = [0.01, 5]
        shapeLayer.lineCap = CAShapeLayerLineCap.round

        let path: UIBezierPath = UIBezierPath()
        path.move(to: CGPoint(x: frame.origin.x + 1, y: frame.origin.y))
        path.addLine(to: CGPoint(x: frame.origin.x + 1, y: frame.origin.y + frame.height))
        shapeLayer.path = path.cgPath

        return shapeLayer
    }
    
    func roundCorners(
        corners: UIRectCorner,
        radius: CGFloat,
        borderColor: UIColor? = nil,
        viewBounds: CGRect? = nil
    ) {
        let path = UIBezierPath(roundedRect: viewBounds ?? bounds, byRoundingCorners: corners, cornerRadii: CGSize(width: radius, height: radius))
        
        let mask = CAShapeLayer()
        mask.path = path.cgPath
        
        if let borderColor = borderColor {
            let shapeLayer = CAShapeLayer()
            shapeLayer.frame = viewBounds ?? bounds
            shapeLayer.path = path.cgPath
            shapeLayer.strokeColor = borderColor.resolvedCGColor(with: self)
            shapeLayer.fillColor = UIColor.clear.resolvedCGColor(with: self)
            shapeLayer.lineWidth = 2
            shapeLayer.masksToBounds = false

            layer.addSublayer(shapeLayer)
        }
        layer.mask = mask
    }
    
    func addShadow(location: VerticalLocation, color: UIColor = UIColor.Sphinx.Shadow, opacity: Float = 0.5, radius: CGFloat = 5.0, bottomhHeight: CGFloat = 3) {
        switch location {
        case .bottom:
            addShadow(offset: CGSize(width: 0, height: bottomhHeight), color: color, opacity: opacity, radius: radius)
        case .bottomLeft:
            addShadow(offset: CGSize(width: -1, height: 2), color: color, opacity: opacity, radius: radius)
        case .top:
            addShadow(offset: CGSize(width: 0, height: -(bottomhHeight)), color: color, opacity: opacity, radius: radius)
        case .center:
            addShadow(offset: CGSize(width: 0, height: 0), color: color, opacity: opacity, radius: radius)
        }
    }
    
    func addShadow(offset: CGSize, color: UIColor = UIColor.Sphinx.Shadow, opacity: Float = 0.5, radius: CGFloat = 5.0) {
        self.layer.masksToBounds = false
        self.layer.shadowColor = color.resolvedCGColor(with: self)
        self.layer.shadowOffset = offset
        self.layer.shadowOpacity = opacity
        self.layer.shadowRadius = radius
    }
    
    func removeShadow() {
        self.layer.shadowColor = UIColor.clear.cgColor
        self.layer.shadowOpacity = 0.0
        self.layer.shadowRadius = 0.0
    }
    
    private static let kRotationAnimationKey = "rotationanimationkey"
    
    func rotate(duration: Double = 1) {
        if layer.animation(forKey: UIView.kRotationAnimationKey) == nil {
            let rotationAnimation = CABasicAnimation(keyPath: "transform.rotation")
            
            rotationAnimation.fromValue = 0.0
            rotationAnimation.toValue = Float.pi * 2.0
            rotationAnimation.duration = duration
            rotationAnimation.repeatCount = Float.infinity
            
            layer.add(rotationAnimation, forKey: UIView.kRotationAnimationKey)
        }
    }
    
    func stopRotating() {
        if layer.animation(forKey: UIView.kRotationAnimationKey) != nil {
            layer.removeAnimation(forKey: UIView.kRotationAnimationKey)
        }
    }
    
    func addCircleLine(tag: String, center: CGPoint, radius: CGFloat, lineWidth: CGFloat) {
        for layer in self.layer.sublayers ?? [] {
            if layer.name == tag {
                layer.removeFromSuperlayer()
            }
        }
        
        let circlePath = UIBezierPath(arcCenter: center, radius: radius, startAngle: CGFloat(0), endAngle: CGFloat(Double.pi * 2), clockwise: true)

        let shapeLayer = CAShapeLayer()
        shapeLayer.path = circlePath.cgPath

        shapeLayer.fillColor = UIColor.clear.resolvedCGColor(with: self)
        shapeLayer.strokeColor = UIColor.white.resolvedCGColor(with: self)
        shapeLayer.lineWidth = lineWidth
        shapeLayer.name = tag

        self.layer.addSublayer(shapeLayer)
    }
    
    func getShapeLayers(onSubviewsWithClasses classes: [AnyClass], andTags tags: [String]) -> [(CGRect, CAShapeLayer)] {
        var layers = [(CGRect, CAShapeLayer)]()
        for subview in self.subviews {
            for c in classes {
                if subview.isKind(of: c) {
                    let subviewLayers = getShapeLayersOn(view: subview, tags: tags)
                    layers.append(contentsOf: subviewLayers)
                    
                    for v in subview.subviews {
                        let vLayers = getShapeLayersOn(view: v, tags: tags)
                        layers.append(contentsOf: vLayers)
                    }
                }
            }
        }
        return layers
    }
    
    func getShapeLayersOn(view: UIView, tags: [String]) -> [(CGRect, CAShapeLayer)] {
        var layers = [(CGRect, CAShapeLayer)]()
        for l in view.layer.sublayers ?? [] {
            if let shapeLayer = l as? CAShapeLayer, let name = shapeLayer.name, let globalRect = view.globalFrame, tags.contains(name) {
                layers.append((globalRect, shapeLayer))
            }
        }
        return layers
    }
    
    func removeAllSubviews() {
        for subview in self.subviews {
            subview.removeFromSuperview()
        }
    }
    
    func addDownTriangle(color: UIColor) {
        let width = self.frame.size.width
        let height = self.frame.size.height
        let path = CGMutablePath()

        path.move(to: CGPoint(x:width/2, y: height))
        path.addLine(to: CGPoint(x:width, y: 0))
        path.addLine(to: CGPoint(x:0, y:0))
        path.addLine(to: CGPoint(x:width/2, y:height))

        let shape = CAShapeLayer()
        shape.path = path
        shape.fillColor = color.cgColor
        shape.lineCap = .round
        shape.lineJoin = .round

        self.layer.insertSublayer(shape, at: 0)
    }
    
    
    func makeCircular() {
        clipsToBounds = true
     
        layer.cornerRadius = min(
            frame.size.width,
            frame.size.height
        ) / 2
    }
    
    func drawReceivedBubbleArrow(
        color: UIColor,
        arrowWidth: CGFloat = 4
    ) {
        let arrowBezierPath = UIBezierPath()
        
        arrowBezierPath.move(to: CGPoint(x: 0, y: 0))
        arrowBezierPath.addLine(to: CGPoint(x: self.frame.width, y: 0))
        arrowBezierPath.addLine(to: CGPoint(x: self.frame.width, y: self.frame.height))
        arrowBezierPath.addLine(to: CGPoint(x: arrowWidth, y: self.frame.height))
        arrowBezierPath.addLine(to: CGPoint(x: 0, y: 0))
        arrowBezierPath.close()
        
        let messageArrowLayer = CAShapeLayer()
        messageArrowLayer.path = arrowBezierPath.cgPath
        
        messageArrowLayer.frame = self.bounds
        messageArrowLayer.fillColor = color.cgColor
        messageArrowLayer.name = "arrow"
        
        self.layer.addSublayer(messageArrowLayer)
    }
    
    func setArrowColorTo(
        color: UIColor
    ) {
        ((self.layer.sublayers?.filter { $0.name == "arrow" })?.first as? CAShapeLayer)?.fillColor = color.cgColor
    }
    
    func drawSentBubbleArrow(
        color: UIColor,
        arrowWidth: CGFloat = 7
    ) {
        let arrowBezierPath = UIBezierPath()
        
        arrowBezierPath.move(to: CGPoint(x: 0, y: 0))
        arrowBezierPath.addLine(to: CGPoint(x: self.frame.width, y: 0))
        arrowBezierPath.addLine(to: CGPoint(x: self.frame.width - arrowWidth, y: self.frame.height))
        arrowBezierPath.addLine(to: CGPoint(x: 0, y: self.frame.height))
        arrowBezierPath.addLine(to: CGPoint(x: 0, y: 0))
        arrowBezierPath.close()
        
        let messageArrowLayer = CAShapeLayer()
        messageArrowLayer.path = arrowBezierPath.cgPath
        
        messageArrowLayer.frame = self.bounds
        messageArrowLayer.fillColor = color.cgColor
        messageArrowLayer.name = "arrow"
        
        self.layer.addSublayer(messageArrowLayer)
    }
    
    func addDashedLineBorder(
        color: UIColor,
        fillColor: UIColor? = nil,
        rect: CGRect,
        roundedBottom: Bool,
        roundedTop: Bool,
        name: String
    ) {
        let shapeLayer:CAShapeLayer = CAShapeLayer()
        shapeLayer.cornerRadius = 8.0
        
        var rounded: UIRectCorner! = nil
        
        if roundedBottom && roundedTop {
            rounded = [.bottomLeft, .bottomRight, .topRight, .topLeft]
        } else if roundedBottom {
            rounded = [.bottomLeft, .bottomRight]
        } else if roundedTop {
            rounded = [.topLeft, .topRight]
        } else {
            rounded = []
        }
        
        shapeLayer.path = UIBezierPath(
            roundedRect: rect,
            byRoundingCorners: rounded,
            cornerRadii: CGSize(width: 8.0, height: 8.0)
        ).cgPath
        
        shapeLayer.fillColor = fillColor?.cgColor ?? UIColor.clear.cgColor
        shapeLayer.strokeColor = color.resolvedCGColor(with: self)
        shapeLayer.lineWidth = 1.5
        shapeLayer.lineJoin = .round
        shapeLayer.lineDashPattern = [8,4]
        shapeLayer.name = name

        self.layer.addSublayer(shapeLayer)
    }

    func removeDashedLineBorderWith(
        name: String
    ) {
        for sublayer in self.layer.sublayers ?? [] {
            if sublayer.name == name {
                sublayer.removeFromSuperlayer()
            }
        }
    }
}
