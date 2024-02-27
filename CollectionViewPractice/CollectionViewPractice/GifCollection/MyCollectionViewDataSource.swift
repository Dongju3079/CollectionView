//
//  MyCollectionViewDataSource.swift
//  CollectionViewPractice
//
//  Created by Macbook on 2/28/24.
//

import Foundation
import UIKit

class MyCollectionViewDataSource: NSObject, UICollectionViewDataSource {
    
    let reloadController: UIRefreshControl = UIRefreshControl()
    
    enum CellType : Int {
        case threeGrid = 0
        case twoGrid
        case table
        case full
    }
    
    var footerState : CustomFooterView.State = .normal
    var isSelectionMode: Bool = false
    
    var cellType: CellType = .threeGrid
    
    var myCollectionView: UICollectionView?

    var gifList: [URL] = []
    var selectedGifList: [String] = []
    
    func configureDataSource(_ collectionView: UICollectionView) {
        self.myCollectionView = collectionView
        collectionView.dataSource = self
        collectionView.collectionViewLayout = UICollectionViewFlowLayout()
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return gifList.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: CustomCollectionViewCell.reuseIdentifier, for: indexPath) as? CustomCollectionViewCell else { return UICollectionViewCell() }
        
        let url = self.gifList[indexPath.item]
        cell.configureCell(cellData: url, isSelectionMode: self.isSelectionMode, selectedGifList: self.selectedGifList)
        
        return cell    }
    
    // 컬렉션 뷰 헤더, 푸터 뷰 구성
    func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        
        switch kind {
        case UICollectionView.elementKindSectionHeader:
            guard let headerView = collectionView.dequeueReusableSupplementaryView(ofKind: UICollectionView.elementKindSectionHeader, withReuseIdentifier: CustomHeaderView.reuseIdentifier, for: indexPath) as? CustomHeaderView else { return UICollectionReusableView() }
            
            headerView.selectionInfoLabel.text = "선택한 움짤 갯수 : \(self.selectedGifList.count)"
            
            return headerView
        default:
            let footerView = collectionView.dequeueReusableSupplementaryView(ofKind: UICollectionView.elementKindSectionFooter, withReuseIdentifier: CustomFooterView.reuseIdentifier, for: indexPath)
            
            if let footerView = footerView as? CustomFooterView {
                footerView.applyState(state: self.footerState)
            }
            
            return footerView
        }
    }
}
