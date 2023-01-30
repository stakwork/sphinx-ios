//
//  DiscoverTribesTagSelectionVM.swift
//  sphinx
//
//  Created by James Carucci on 1/16/23.
//  Copyright © 2023 sphinx. All rights reserved.
//

import Foundation
import UIKit

class DiscoverTribesTagSelectionVM : NSObject {
    var vc: DiscoverTribesTagSelectionVC
    
    let columnLayout = FlowLayout(
        minimumInteritemSpacing: 10,
        minimumLineSpacing: 16,
        sectionInset: UIEdgeInsets(top: 10, left: 10, bottom: 10, right: 10)
    )
    
    let possibleTags : [String] = [
        "Bitcoin",
        "NSFW",
        "Lightning",
        "Podcast",
        "Crypto",
        "Music",
        "Tech",
        "Altcoins"
    ]
    var selectedTags : [String] = []
    var collectionView : UICollectionView
    
    init(vc: DiscoverTribesTagSelectionVC, collectionView: UICollectionView) {
        self.vc = vc
        self.collectionView = collectionView
        
        super.init()
        
        collectionView.collectionViewLayout = columnLayout
        collectionView.contentInsetAdjustmentBehavior = .always
        collectionView.register(TribeTagSelectionCollectionViewCell.self, forCellWithReuseIdentifier: "TribeTagSelectionCollectionViewCell")
        collectionView.reloadData()
    }
    
    func getSelectionStatus(index:Int) -> Bool {
        let tag = possibleTags[index]
        if selectedTags.contains(tag) {
            return true
        } else {
            return false
        }
    }
}


extension DiscoverTribesTagSelectionVM : UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return possibleTags.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = self.collectionView.dequeueReusableCell(withReuseIdentifier: "TribeTagSelectionCollectionViewCell", for: indexPath) as! TribeTagSelectionCollectionViewCell
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, willDisplay cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        if let cell = cell as? TribeTagSelectionCollectionViewCell {
            
            cell.configureWith(
                tag: possibleTags[indexPath.row],
                selected: getSelectionStatus(index: indexPath.row)
            )
        }
    }
}

extension DiscoverTribesTagSelectionVM : UICollectionViewDelegate{
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        print(possibleTags[indexPath.row])
        handleSelectDeselect(index: indexPath.row)
    }
    
    func handleSelectDeselect(index:Int){
        let tag = possibleTags[index]
        if selectedTags.contains(tag){
            selectedTags.removeAll(where: {$0 == tag})
        }
        else{
            selectedTags.append(possibleTags[index])
        }
        collectionView.reloadData()
    }
}

class FlowLayout: UICollectionViewFlowLayout {

    required init(
        minimumInteritemSpacing: CGFloat = 0,
        minimumLineSpacing: CGFloat = 0,
        sectionInset: UIEdgeInsets = .zero
    ) {
        super.init()

        estimatedItemSize = UICollectionViewFlowLayout.automaticSize
        self.minimumInteritemSpacing = minimumInteritemSpacing
        self.minimumLineSpacing = minimumLineSpacing
        self.sectionInset = sectionInset
        sectionInsetReference = .fromSafeArea
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layoutAttributesForElements(
        in rect: CGRect
    ) -> [UICollectionViewLayoutAttributes]? {
        let layoutAttributes = super.layoutAttributesForElements(in: rect)!.map { $0.copy() as! UICollectionViewLayoutAttributes }
        guard scrollDirection == .vertical else { return layoutAttributes }

        let cellAttributes = layoutAttributes.filter({ $0.representedElementCategory == .cell })
        
        for (_, attributes) in Dictionary(grouping: cellAttributes, by: { ($0.center.y / 10).rounded(.up) * 10 }) {
            
            let cellsTotalWidth = attributes.reduce(CGFloat(0)) { (partialWidth, attribute) -> CGFloat in
                partialWidth + attribute.size.width
            }

            let totalInset = collectionView!.safeAreaLayoutGuide.layoutFrame.width - cellsTotalWidth - sectionInset.left - sectionInset.right - minimumInteritemSpacing * CGFloat(attributes.count - 1)
            var leftInset = (totalInset / 2 * 10).rounded(.down) / 10 + sectionInset.left

            for attribute in attributes {
                attribute.frame.origin.x = leftInset
                leftInset = attribute.frame.maxX + minimumInteritemSpacing
            }
        }

        return layoutAttributes
    }

}
