//
//  SelectedGifDataSource.swift
//  CollectionViewPractice
//
//  Created by Macbook on 2/27/24.
//

import Foundation
import UIKit

class SelectedGifDataSource: NSObject, UICollectionViewDataSource {
    
    var myCollectionView: UICollectionView?
    var delegate: GifSelectionDelegate?
    
    var selectedGifList: [String] = []
    
    let selectedCollectionViewFlowLayout: UICollectionViewFlowLayout = {
        let flow = UICollectionViewFlowLayout()
        flow.scrollDirection = .horizontal
        flow.itemSize = CGSize(width: 80, height: 80)
        flow.sectionInset = UIEdgeInsets(top: 10, left: 10, bottom: 10, right: 10)
        return flow
    }()
    
    func configureDataSource(_ collectionView: UICollectionView, _ delegate: GifSelectionDelegate) {
        self.myCollectionView = collectionView
        self.delegate = delegate
        collectionView.dataSource = self
        collectionView.collectionViewLayout = selectedCollectionViewFlowLayout
        collectionView.showsHorizontalScrollIndicator = false
        
        let selectedNibCell = UINib(nibName: SelectedCell.reuseIdentifier, bundle: .main)
        collectionView.register(selectedNibCell, forCellWithReuseIdentifier: SelectedCell.reuseIdentifier)
    }
    
    func setData(newData: [String]) {
        self.selectedGifList = newData
        let indexSet = IndexSet(integer: 0)
        self.myCollectionView?.reloadSections(indexSet)
    }
    
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return selectedGifList.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: SelectedCell.reuseIdentifier, for: indexPath) as? SelectedCell else { return UICollectionViewCell() }
        
        let url = self.selectedGifList[indexPath.item]
        
        if let delegate = delegate {
            cell.configureCell(cellData: url, delegate: delegate)
        }
        
        return cell
    }
}
