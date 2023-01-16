//
//  DiscoverTribesTagSelectionVM.swift
//  sphinx
//
//  Created by James Carucci on 1/16/23.
//  Copyright © 2023 sphinx. All rights reserved.
//

import Foundation
import UIKit

class DiscoverTribesTagSelectionVM : NSObject{
    var vc: DiscoverTribesTagSelectionVC
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
    
    init(vc:DiscoverTribesTagSelectionVC,collectionView:UICollectionView) {
        self.vc = vc
        self.collectionView = collectionView
    }
    
    func getSelectionStatus(index:Int)->Bool{
        let tag = possibleTags[index]
        if selectedTags.contains(tag){
            return true
        }
        else{
            return false
        }
    }
}


extension DiscoverTribesTagSelectionVM : UICollectionViewDataSource{
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return possibleTags.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = self.collectionView.dequeueReusableCell(withReuseIdentifier: "tagCell", for: indexPath) as! TribeTagSelectionCollectionViewCell
        if(getSelectionStatus(index: indexPath.row)){
            cell.contentView.backgroundColor = UIColor.Sphinx.BodyInverted
            cell.tagLabel.textColor = UIColor.Sphinx.Body
        }
        else{
            cell.contentView.backgroundColor = UIColor.Sphinx.ReceivedMsgBG
            cell.tagLabel.textColor = UIColor.Sphinx.BodyInverted
        }
        cell.layer.cornerRadius = 20.0
        cell.tagLabel.text = possibleTags[indexPath.row]
        
        return cell
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
