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
    
    @IBOutlet weak var filterIcon: UILabel!
    @IBOutlet weak var applyButton: UIButton!
    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var tagSelectionView: UIView!
    
    
    var delegate : DiscoverTribesTagSelectionDelegate?
    lazy var discoverTribeTagSelectionVM: DiscoverTribesTagSelectionVM = {
        return DiscoverTribesTagSelectionVM(vc: self, collectionView: collectionView)
    }()
    
    static func instantiate(
        rootViewController: RootViewController
    ) -> DiscoverTribesTagSelectionVC {
        let viewController = StoryboardScene.Welcome.discoverTribesTagSelectionViewController.instantiate()
        //viewController.rootViewController = rootViewController
        viewController.view.backgroundColor = .clear
        viewController.collectionView.backgroundColor = viewController.view.backgroundColor
        //viewController.tagSelectionView.backgroundColor = viewController.tagSelectionView.backgroundColor?.withAlphaComponent(0.85)
        
        return viewController
    }
    
    override func viewDidLoad() {
        styleLabels()
        styleApplyButton()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        self.setupCollectionView()
    }
    
    func styleLabels(){
        filterIcon.font = UIFont(name: "Material Icons", size: 18.0)
        filterIcon.text = "filter"
        filterIcon.textColor = UIColor.Sphinx.BodyInverted
    }
    
    func styleApplyButton(){
        applyButton.layer.cornerRadius = 24.0
        applyButton.addTarget(self, action: #selector(handleApplyTap), for: .touchUpInside)
    }
    
    func setupCollectionView(){
        collectionView.delegate = discoverTribeTagSelectionVM
        collectionView.dataSource = discoverTribeTagSelectionVM
    }
    
    @objc func handleApplyTap(){
        delegate?.didSelect(selections: self.discoverTribeTagSelectionVM.selectedTags)
        self.dismiss(animated: true)
    }
    
    
}
