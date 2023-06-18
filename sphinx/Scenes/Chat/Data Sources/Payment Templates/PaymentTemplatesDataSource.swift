//
//  PaymentTemplatesDataSource.swift
//  sphinx
//
//  Created by Tomas Timinskas on 12/03/2020.
//  Copyright © 2020 Sphinx. All rights reserved.
//

import UIKit

protocol PaymentTemplatesDSDelegate: class {
    func didSelectImage(image: ImageTemplate?)
}

struct ImageTemplate {
    
    var width: Int? = nil
    var height: Int? = nil
    var muid: String? = nil
    
    init() {}
    
    init(muid: String?, width: Int?, height: Int?) {
        self.muid = muid
        self.width = width
        self.height = height
    }
}

class PaymentTemplatesDataSource: NSObject {
    
    weak var delegate: PaymentTemplatesDSDelegate?
    
    var collectionView : UICollectionView!
    
    let kCellHeight: CGFloat = 85.0
    let kCellWidth: CGFloat = 78.0
    
    var isDragging = false
    var images = [ImageTemplate]()
    var selectedRow = 0
    
    init(collectionView: UICollectionView, delegate: PaymentTemplatesDSDelegate, images: [ImageTemplate]) {
        super.init()
        
        self.delegate = delegate
        self.collectionView = collectionView
        self.images = images
        
        let sideInset = WindowsManager.getWindowWidth() / 2 - kCellWidth / 2
        self.collectionView.contentInset = UIEdgeInsets(top: 0, left: sideInset, bottom: 0, right: sideInset)
    }
}

extension PaymentTemplatesDataSource : UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, willDisplay cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        if let cell = cell as? PaymentTemplateCollectionViewCell {
            if indexPath.row > 0 {
                cell.configure(rowIndex: indexPath.row, imageTemplate: images[indexPath.row - 1])
            } else {
                cell.configure(rowIndex: indexPath.row, imageTemplate: nil)
            }
        }
    }
}

extension PaymentTemplatesDataSource: UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize(width: kCellWidth, height: kCellHeight)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return 0.0
    }
}

extension PaymentTemplatesDataSource : UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "PaymentTemplateCollectionViewCell", for: indexPath) as! PaymentTemplateCollectionViewCell
        return cell
    }
    
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return images.count + 1
    }
}

extension PaymentTemplatesDataSource : UIScrollViewDelegate {
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        if let centerIndexPath = getCenterClosestIndexPath() {
            if selectedRow == centerIndexPath.row {
                return
            }

            selectedRow = centerIndexPath.row

            let image = (selectedRow > 0) ? images[selectedRow - 1] : nil
            delegate?.didSelectImage(image: image)
        }
    }
    
    func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        isDragging = false
        
        if !decelerate {
            scrollToClosest()
        }
    }
    
    func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        isDragging = true
    }
    
    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        if !isDragging {
            scrollToClosest()
        }
    }
    
    func scrollToClosest() {
        if let indexPath = getCenterClosestIndexPath() {
            collectionView.scrollToItem(at: indexPath, at: .centeredHorizontally, animated: true)
        }
    }
    
    func getCenterClosestIndexPath() -> IndexPath? {
        if collectionView.visibleCells.count == 0 {
            return nil
        }
        
        var closestCell: UICollectionViewCell = collectionView.visibleCells[0]

        for cell in collectionView.visibleCells as [UICollectionViewCell] {
            if let cell = cell as? PaymentTemplateCollectionViewCell {
                let closestCellDelta = abs(closestCell.center.x - collectionView.bounds.size.width/2.0 - collectionView.contentOffset.x)
                let cellDelta = abs(cell.center.x - collectionView.bounds.size.width/2.0 - collectionView.contentOffset.x)
                if (cellDelta < closestCellDelta){
                    closestCell = cell
                }
            }
        }
        if let centerIndexPath = collectionView.indexPath(for: closestCell) {
            return centerIndexPath
        }
        
        return nil
    }
}

