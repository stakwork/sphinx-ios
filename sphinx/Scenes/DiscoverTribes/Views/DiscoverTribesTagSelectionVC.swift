//
//  DiscoverTribesTagSelectionVC.swift
//  sphinx
//
//  Created by James Carucci on 1/16/23.
//  Copyright © 2023 sphinx. All rights reserved.
//

import Foundation
import UIKit


protocol DiscoverTribesTagSelectionDelegate{
    func didSelect(selections:[String])
}

class DiscoverTribesTagSelectionVC : UIViewController{
    
    @IBOutlet weak var blurEffectView: UIView!
    @IBOutlet weak var filterIcon: UILabel!
    @IBOutlet weak var applyButton: UIButton!
    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var tagSelectionView: UIView!
    @IBOutlet weak var tagsLabel: UILabel!
    @IBOutlet weak var panGestureLine: UIView!
    @IBOutlet weak var panGestureView: UIView!
    
    @IBOutlet weak var tagsSelectionViewBottomConstraint: NSLayoutConstraint!
    
    var delegate : DiscoverTribesTagSelectionDelegate?
    
    lazy var discoverTribeTagSelectionVM: DiscoverTribesTagSelectionVM = {
        return DiscoverTribesTagSelectionVM(vc: self, collectionView: collectionView)
    }()
    
    static func instantiate() -> DiscoverTribesTagSelectionVC {
        let viewController = StoryboardScene.Welcome.discoverTribesTagSelectionViewController.instantiate()
        return viewController
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        styleApplyButton()
        setupCollectionView()
        setupDismissableView()
        styleTagsView()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        animateView(show: true)
    }
    
    func animateView(
        show: Bool,
        completion: (() -> ())? = nil
    ) {
        let newConstant: CGFloat = show ? 0 : -600
        
        if (tagsSelectionViewBottomConstraint.constant == newConstant) {
            return
        }
        
        tagsSelectionViewBottomConstraint.constant = newConstant
        
        UIView.animate(withDuration: 0.25, animations: {
            self.tagSelectionView.superview?.layoutIfNeeded()
            self.collectionView.reloadData()
            self.view.alpha = show ? 1.0 : 0.0
        }) { _ in
            completion?()
        }
    }
    
    func styleTagsView() {
        tagSelectionView.layer.cornerRadius = 20
        tagSelectionView.clipsToBounds = true
        
        addBlur()
    }
    
    func addBlur(){
        let blurEffect = UIBlurEffect(style: UIBlurEffect.Style.prominent)
        let effectView = UIVisualEffectView(effect: blurEffect)
        effectView.frame = tagSelectionView.bounds
        effectView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        tagSelectionView.addSubview(effectView)
        tagSelectionView.sendSubviewToBack(effectView)
    }
    
    func styleApplyButton(){
        applyButton.makeCircular()
    }
    
    func setupCollectionView(){
        collectionView.delegate = discoverTribeTagSelectionVM
        collectionView.dataSource = discoverTribeTagSelectionVM
    }
    
    @IBAction func applyButtonTouched() {
        delegate?.didSelect(selections: self.discoverTribeTagSelectionVM.selectedTags)
        
        animateView(show: false) {
            self.dismiss(animated: false)
        }
    }
    
    func setupDismissableView() {
        panGestureLine.makeCircular()
        
        let panGesture = UIPanGestureRecognizer(target: self, action: #selector(panGestureRecognizerAction))
        panGestureView.addGestureRecognizer(panGesture)
    }
    
    @objc func panGestureRecognizerAction(sender: UIPanGestureRecognizer) {
        let translation = sender.translation(in: view).y

        guard translation >= 0 else { return }
        
        if sender.state == .began {
            tagsSelectionViewBottomConstraint.constant = 0
            tagSelectionView.superview?.layoutIfNeeded()
            return
        }
        
        if sender.state == .changed {
            tagsSelectionViewBottomConstraint.constant = -translation
            tagSelectionView.superview?.layoutIfNeeded()
            return
        }

        if sender.state == .ended {
            if translation > 200 {
                animateView(show: false) {
                    self.dismiss(animated: false)
                }
            } else {
                animateView(show: true)
            }
        }
    }
}
