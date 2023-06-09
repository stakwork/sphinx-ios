//
//  CircularProgressView.swift
//  sphinx
//
//  Created by Tomas Timinskas on 09/03/2023.
//  Copyright © 2023 sphinx. All rights reserved.
//

import UIKit

class CircularProgressView: UIView {
    
    @IBOutlet var contentView: UIView!
    @IBOutlet weak var playPauseLabel: UILabel!
    
    private var circleLayer = CAShapeLayer()
    private var progressLayer = CAShapeLayer()
    private var startPoint = CGFloat(-Double.pi / 2)
    private var endPoint = CGFloat(3 * Double.pi / 2)

    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setup()
    }
    
    private func setup() {
        Bundle.main.loadNibNamed("CircularProgressView", owner: self, options: nil)
        addSubview(contentView)
        contentView.frame = self.bounds
        contentView.autoresizingMask = [.flexibleHeight, .flexibleWidth]
        
        playPauseLabel.font = UIFont(name: "MaterialIcons-Regular", size: 15.0)
        
        createCircularPath()
    }
    
    func createCircularPath() {
        let circularPath = UIBezierPath(
            arcCenter: CGPoint(x: frame.size.width / 2.0, y: frame.size.height / 2.0),
            radius: frame.size.height / 2.0,
            startAngle: startPoint,
            endAngle: endPoint,
            clockwise: true
        )
        
        // circleLayer path defined to circularPath
        circleLayer.path = circularPath.cgPath
        // ui edits
        circleLayer.fillColor = UIColor.clear.cgColor
        circleLayer.lineCap = .round
        circleLayer.lineWidth = 2.0
        circleLayer.strokeEnd = 1.0
        circleLayer.strokeColor = UIColor.Sphinx.Text.withAlphaComponent(0.1).cgColor
        // added circleLayer to layer
        layer.addSublayer(circleLayer)
        // progressLayer path defined to circularPath
        progressLayer.path = circularPath.cgPath
        // ui edits
        progressLayer.fillColor = UIColor.clear.cgColor
        progressLayer.lineCap = .round
        progressLayer.lineWidth = 2.0
        progressLayer.strokeEnd = 0.0
        progressLayer.strokeColor = UIColor.Sphinx.ReceivedIcon.cgColor
        // added progressLayer to layer
        layer.addSublayer(progressLayer)
    }
    
    func startRotation(){
        // Create a CABasicAnimation for rotation
        let rotationAnimation = CABasicAnimation(keyPath: "transform.rotation.z")
        rotationAnimation.fromValue = 0.0
        rotationAnimation.toValue = CGFloat.pi * 2.0 // 360 degrees
        rotationAnimation.duration = 2.0  // Duration of one full rotation
        rotationAnimation.repeatCount = .infinity  // Repeat indefinitely

        // Add the animation to the view's layer
        self.layer.add(rotationAnimation, forKey: "rotationAnimation")
        self.layer.speed = 2.0
    }
    
    func stopRotation() {
        // Remove the rotation animation from the view's layer
        self.layer.removeAnimation(forKey: "rotationAnimation")

        // Set the layer's transform to the current presentation layer transform
        if let presentationLayer = self.layer.presentation() {
            self.layer.transform = presentationLayer.transform
        }

        // Remove any pending animations
        self.layer.removeAllAnimations()
    }

    
    func setProgressStrokeColor(color:UIColor){
        progressLayer.strokeColor = color.cgColor
    }
    
    func progressAnimation(
        to: CGFloat,
        active: Bool
    ) {
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        progressLayer.strokeEnd = to
        CATransaction.commit()
        
        playPauseLabel.isHidden = to == 0
        playPauseLabel.text = active ? "pause" : "play_arrow"
    }
}
