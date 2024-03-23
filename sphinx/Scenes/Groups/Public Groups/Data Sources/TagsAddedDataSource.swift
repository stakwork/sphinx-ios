//
//  TagsAddedDataSource.swift
//  sphinx
//
//  Created by Tomas Timinskas on 19/05/2020.
//  Copyright © 2020 Sphinx. All rights reserved.
//

import UIKit

class TagsAddedDataSource: NSObject {
    
    var collectionView : UICollectionView!
    
    let kCellHeight: CGFloat = 50.0
    
    var tags = [GroupsManager.Tag]()
    var addButtonTapped: (() -> ())?
    var tagSelected: ((Int) -> ())?
    
    init(collectionView: UICollectionView) {
        super.init()
        self.collectionView = collectionView
        self.collectionView.registerCell(GroupTagCollectionViewCell.self)
        // Register your footer view class
        self.collectionView.register(AddTagsButtonCell.self, forSupplementaryViewOfKind: UICollectionView.elementKindSectionFooter, withReuseIdentifier: AddTagsButtonCell.reuseIdentifier)
    }
    
    func setTags(tags: [GroupsManager.Tag]) {
        self.tags = tags.filter{ $0.selected }
        
        let alignedFlowLayout = collectionView?.collectionViewLayout as? AlignedCollectionViewFlowLayout
        alignedFlowLayout?.horizontalAlignment = .left
        alignedFlowLayout?.verticalAlignment = .top
        
        collectionView.delegate = self
        collectionView.dataSource = self
        collectionView.reloadData()
    }
}

extension TagsAddedDataSource : UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, willDisplay cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        if let cell = cell as? GroupTagCollectionViewCell {
            let tag = tags[indexPath.row]
            cell.configureWith(tag: tag)
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        if kind == UICollectionView.elementKindSectionFooter {
            let footerView = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: AddTagsButtonCell.reuseIdentifier, for: indexPath) as! AddTagsButtonCell
            // Configure your footer view
            footerView.titleLabel.text = "Add Tags"
            // Add tap gesture recognizer to the footer view
            let tapGesture = UITapGestureRecognizer(target: self, action: #selector(footerViewTapped(_:)))
            footerView.addGestureRecognizer(tapGesture)
            return footerView
        }
        // Handle other kinds of supplementary views if needed
        fatalError("Unexpected kind of supplementary view")
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        tagSelected?(indexPath.row)
    }
    
    @objc func footerViewTapped(_ sender: UITapGestureRecognizer) {
        // Handle footer view tap here
        addButtonTapped?()
    }
    
}

extension TagsAddedDataSource: UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let tag = tags[indexPath.row]
        let width = GroupTagView.getWidthWith(description: tag.description)
        return CGSize(width: width, height: kCellHeight)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return 0.0
    }
    
    // MARK: - UICollectionViewDelegateFlowLayout methods
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForFooterInSection section: Int) -> CGSize {
        // Return size for footer view
        return CGSize(width: collectionView.frame.width, height: 50) // You can adjust the height as per your requirement
    }
}

extension TagsAddedDataSource : UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "GroupTagCollectionViewCell", for: indexPath) as! GroupTagCollectionViewCell
        return cell
    }
    
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return tags.count
    }
}
