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
    
    
    var delegate : DiscoverTribesTagSelectionDelegate?
    
    lazy var discoverTribeTagSelectionVM: DiscoverTribesTagSelectionVM = {
        return DiscoverTribesTagSelectionVM(vc: self, collectionView: collectionView)
    }()
    
    static func instantiate(
        rootViewController: RootViewController
    ) -> DiscoverTribesTagSelectionVC {
        let viewController = StoryboardScene.Welcome.discoverTribesTagSelectionViewController.instantiate()
        viewController.view.backgroundColor = .clear
        viewController.collectionView.backgroundColor = .clear
        viewController.collectionView.backgroundColor = viewController.view.backgroundColor
        return viewController
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        styleApplyButton()
        setupCollectionView()
        styleTagsView()
    }
    
    func styleTagsView() {
        tagSelectionView.roundCorners(corners: [.topLeft, .topRight], radius: 20.0)
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
        self.dismiss(animated: true)
    }
}
