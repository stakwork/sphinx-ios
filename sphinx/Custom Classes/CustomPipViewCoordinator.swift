//
//  CustomPipViewCoordinator.swift
//  sphinx
//
//  Created by Tomas Timinskas on 05/03/2020.
//  Copyright © 2020 Sphinx. All rights reserved.
//

import UIKit

public typealias AnimationCompletion = (Bool) -> Void

public protocol CustomPipViewCoordinatorDelegate: class {
    func enterPictureInPicture()
    func exitPictureInPicture()
}

public class CustomPipViewCoordinator {

    public var dragBoundInsets: UIEdgeInsets = UIEdgeInsets(top: 35,
                                                            left: 5,
                                                            bottom: 100,
                                                            right: 5) {
        didSet {
            dragController.insets = dragBoundInsets
        }
    }

    public enum Position {
        case lowerRightCorner
        case upperRightCorner
        case lowerLeftCorner
        case upperLeftCorner
    }
    
    public var initialPositionInSuperview = Position.lowerRightCorner
    
    public var pipSizeHeightRatio: CGFloat = {
        let deviceIdiom = UIScreen.main.traitCollection.userInterfaceIdiom
        switch deviceIdiom {
        case .pad:
            return 0.25
        case .phone:
            return 0.40
        default:
            return 0.25
        }
    }()
    
    public var pipSizeWidthRatio: CGFloat = {
        let deviceIdiom = UIScreen.main.traitCollection.userInterfaceIdiom
        switch deviceIdiom {
        case .pad:
            return 0.25
        case .phone:
            return 0.50
        default:
            return 0.25
        }
    }()
    
    public weak var delegate: CustomPipViewCoordinatorDelegate?

    private(set) var isInPiP: Bool = false

    private(set) var view: UIView
    private var currentBounds: CGRect = CGRect.zero

    private var tapGestureRecognizer: UITapGestureRecognizer?
    private var exitPiPButton: UIButton?

    private let dragController: DragGestureController = DragGestureController()

    public init(withView view: UIView) {
        self.view = view
        
        NotificationCenter.default.addObserver(self, selector: #selector(onKeyboardShown(_:)), name: .onKeyboardShown, object: nil)
    }

    public func configureAsStickyView(withParentView parentView: UIView? = nil) {
        guard
            let parentView = parentView
            else { return }
        
        parentView.addSubview(view)
        currentBounds = parentView.bounds
        view.frame = currentBounds
        view.layer.zPosition = CGFloat(Float.greatestFiniteMagnitude).nextDown
    }

    public func show(completion: AnimationCompletion? = nil) {
        if view.isHidden || view.alpha < 1 {
            view.isHidden = false
            view.alpha = 0

            animateTransition(animations: { [weak self] in
                self?.view.alpha = 1
            }, completion: completion)
        }
    }

    public func hide(completion: AnimationCompletion? = nil) {
        if view.isHidden || view.alpha > 0 {
            animateTransition(animations: { [weak self] in
                self?.view.alpha = 0
                self?.view.isHidden = true
            }, completion: completion)
        }
    }

    public func enterPictureInPicture() {
        isInPiP = true
        animateViewChange()
        dragController.startDragListener(inView: view)
        dragController.insets = dragBoundInsets

        let exitSelector = #selector(toggleExitPiP)
        let tapGestureRecognizer = UITapGestureRecognizer(target: self,
                                                          action: exitSelector)
        self.tapGestureRecognizer = tapGestureRecognizer
        view.addGestureRecognizer(tapGestureRecognizer)
        
        delegate?.enterPictureInPicture()
    }

    @objc public func exitPictureInPicture() {
        isInPiP = false
        animateViewChange()
        dragController.stopDragListener()

        exitPiPButton?.removeFromSuperview()
        exitPiPButton = nil

        let exitSelector = #selector(toggleExitPiP)
        tapGestureRecognizer?.removeTarget(self, action: exitSelector)
        tapGestureRecognizer = nil
        
        delegate?.exitPictureInPicture()
    }

    public func resetBounds(bounds: CGRect) {
        currentBounds = bounds
        exitPictureInPicture()
    }

    public func stopDragGesture() {
        dragController.stopDragListener()
    }

    open func configureExitPiPButton(target: Any,
                                     action: Selector) -> UIButton {
        let buttonImage = UIImage.init(named: "image-resize",
                                       in: Bundle(for: type(of: self)),
                                       compatibleWith: nil)
        let button = UIButton(type: .custom)
        let size: CGSize = CGSize(width: 44, height: 44)
        button.setImage(buttonImage, for: .normal)
        button.backgroundColor = .gray
        button.layer.cornerRadius = size.width / 2
        button.frame = CGRect(origin: CGPoint.zero, size: size)
        button.center = view.convert(view.center, from: view.superview)
        button.addTarget(target, action: action, for: .touchUpInside)
        return button
    }

    @objc private func toggleExitPiP() {
        if exitPiPButton == nil {
            // show button
            let exitSelector = #selector(exitPictureInPicture)
            let button = configureExitPiPButton(target: self,
                                                action: exitSelector)
            view.addSubview(button)
            exitPiPButton = button

        } else {
            // hide button
            exitPiPButton?.removeFromSuperview()
            exitPiPButton = nil
        }
    }

    private func animateViewChange() {
        UIView.animate(withDuration: 0.25) {
            self.view.frame = self.changeViewRect()
            self.view.setNeedsLayout()
        }
    }

    private func changeViewRect() -> CGRect {
        let bounds = currentBounds

        guard isInPiP else {
            return bounds
        }

        let adjustedBounds = bounds.inset(by: dragBoundInsets)
        let size = CGSize(width: bounds.size.width * pipSizeWidthRatio,
                          height: bounds.size.height * pipSizeHeightRatio)
        let origin = initialPositionFor(pipSize: size, bounds: adjustedBounds)
        return CGRect(x: origin.x, y: origin.y, width: size.width, height: size.height)
    }
    
    private func initialPositionFor(pipSize size: CGSize, bounds: CGRect) -> CGPoint {
        switch initialPositionInSuperview {
        case .lowerLeftCorner:
            return CGPoint(x: bounds.minX, y: bounds.maxY - size.height)
        case .lowerRightCorner:
            return CGPoint(x: bounds.maxX - size.width, y: bounds.maxY - size.height)
        case .upperLeftCorner:
            return CGPoint(x: bounds.minX, y: bounds.minY)
        case .upperRightCorner:
            return CGPoint(x: bounds.maxX - size.width, y: bounds.minY)
        }
    }
    
    @objc func onKeyboardShown(_ notification:Notification) {
        moveToTop()
    }
    
    func moveToTop() {
        let currentPos = view.frame.origin
        let finalPos = CGPoint(x: currentPos.x, y: dragBoundInsets.top)

        var frame: CGRect = view.frame
        frame.origin = CGPoint(x: finalPos.x, y: finalPos.y)

        UIView.animate(withDuration: 0.5,
                       delay: 0,
                       usingSpringWithDamping: 0.9,
                       initialSpringVelocity: 1,
                       options: .curveLinear,
                       animations: {
                        self.view.frame = frame
        }, completion: nil)
    }

    private func animateTransition(animations: @escaping () -> Void,
                                   completion: AnimationCompletion?) {
        UIView.animate(withDuration: 0.1,
                       delay: 0,
                       options: .beginFromCurrentState,
                       animations: animations,
                       completion: completion)
    }
}

final class DragGestureController {

    var insets: UIEdgeInsets = UIEdgeInsets.zero

    private var frameBeforeDragging: CGRect = CGRect.zero
    private weak var view: UIView?
    private lazy var panGesture: UIPanGestureRecognizer = {
        return UIPanGestureRecognizer(target: self,
                                      action: #selector(handlePan(gesture:)))
    }()

    func startDragListener(inView view: UIView) {
        self.view = view
        view.addGestureRecognizer(panGesture)
        panGesture.isEnabled = true
    }

    func stopDragListener() {
        panGesture.isEnabled = false
        view?.removeGestureRecognizer(panGesture)
        view = nil
    }

    @objc private func handlePan(gesture: UIPanGestureRecognizer) {
        guard let view = self.view else { return }

        let translation = gesture.translation(in: view.superview)
        let velocity = gesture.velocity(in: view.superview)
        var frame = frameBeforeDragging

        switch gesture.state {
        case .began:
            frameBeforeDragging = view.frame

        case .changed:
            frame.origin.x = floor(frame.origin.x + translation.x)
            frame.origin.y = floor(frame.origin.y + translation.y)
            view.frame = frame

        case .ended:
            let currentPos = view.frame.origin
            let finalPos = calculateFinalPosition()

            let distance = CGPoint(x: currentPos.x - finalPos.x,
                                   y: currentPos.y - finalPos.y)
            let distanceMagnitude = magnitude(vector: distance)
            let velocityMagnitude = magnitude(vector: velocity)
            let animationDuration = 0.5
            let initialSpringVelocity =
                velocityMagnitude / distanceMagnitude / CGFloat(animationDuration)

            frame.origin = CGPoint(x: finalPos.x, y: finalPos.y)

            UIView.animate(withDuration: animationDuration,
                           delay: 0,
                           usingSpringWithDamping: 0.9,
                           initialSpringVelocity: initialSpringVelocity,
                           options: .curveLinear,
                           animations: {
                            view.frame = frame
            }, completion: nil)

        default:
            break
        }
    }

    private func calculateFinalPosition() -> CGPoint {
        guard
            let view = self.view,
            let bounds = view.superview?.frame
            else { return CGPoint.zero }

        let currentSize = view.frame.size
        let adjustedBounds = bounds.inset(by: insets)
        let threshold: CGFloat = 20.0
        let velocity = panGesture.velocity(in: view.superview)
        let location = panGesture.location(in: view.superview)

        let goLeft: Bool
        if abs(velocity.x) > threshold {
            goLeft = velocity.x < -threshold
        } else {
            goLeft = location.x < bounds.midX
        }

        let goUp: Bool
        if abs(velocity.y) > threshold {
            goUp = velocity.y < -threshold
        } else {
            goUp = location.y < bounds.midY
        }

        let finalPosX: CGFloat =
            goLeft
                ? adjustedBounds.origin.x
                : bounds.size.width - insets.right  - currentSize.width
        let finalPosY: CGFloat =
            goUp
                ? adjustedBounds.origin.y
                : bounds.size.height - insets.bottom - currentSize.height

        return CGPoint(x: finalPosX, y: finalPosY)
    }

    private func magnitude(vector: CGPoint) -> CGFloat {
        return sqrt(pow(vector.x, 2) + pow(vector.y, 2))
    }
}
