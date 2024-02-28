//
//  MyCollectionViewDataSource.swift
//  CollectionViewPractice
//
//  Created by Macbook on 2/28/24.
//

import Foundation
import UIKit

class MyCollectionViewDataSource: NSObject, UICollectionViewDataSource {
    
    enum CellType : Int {
        case threeGrid = 0
        case twoGrid
        case table
        case full
        case list
    }
    
    // MARK: - UIComponent
    var myCollectionView: UICollectionView?
    let reloadController: UIRefreshControl = UIRefreshControl()
    
    // MARK: - closure
    var insertSelectedGifList: (IndexPath) -> Void = { indexPath in }
    var updateHeaderView: (UICollectionView) -> Void = { collectionView in }
    var fetchMoreGifList: ((() -> Void)?) -> Void = { completion in }
    var footerApplyState: (CustomFooterView.State) -> Void = { state in }
    
    // MARK: - Variables
    // 선택됐는지
    var isSelectionMode: Bool = false
    
    // 데이터를 가지고 오는 중인지
    var isFetchingMore : Bool = false
    
    // 푸터의 현재 상태
    var footerState : CustomFooterView.State = .normal
    
    // sag에 따라서 셀을 어떻게 표현할 지
    var cellType: CellType = .threeGrid
    
    // 처음 가져온 데이터
    var gifList: [URL] = []
    
    // 선택된 데이터
    var selectedGifList: [String] = []
    
    /// 컬렉션뷰 설정
    func configureDataSource(_ collectionView: UICollectionView) {
        self.myCollectionView = collectionView
        collectionView.dataSource = self
        collectionView.delegate = self
        collectionView.collectionViewLayout = UICollectionViewFlowLayout()
    }
}

// MARK: - DataSource
extension MyCollectionViewDataSource {
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

// MARK: - Delegate
extension MyCollectionViewDataSource : UICollectionViewDelegate {
    
    // 선택이 되기 전 (선택되게 할 것인지에 대한 Bool)
    func collectionView(_ collectionView: UICollectionView, shouldSelectItemAt indexPath: IndexPath) -> Bool {
        return self.isSelectionMode
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        print(#fileID, #function, #line, "- ")
        
        self.insertSelectedGifList(indexPath)
        
        collectionView.reloadItems(at: [indexPath])
        
        updateHeaderView(collectionView)
    }
}

// MARK: - DelegateFlowLayout
extension MyCollectionViewDataSource : UICollectionViewDelegateFlowLayout {
    
    // 설정별 셀 크기 조정 및 dynamic 사이즈 조절
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        
        let fullWidth = collectionView.bounds.width
        let fullHeight = collectionView.bounds.height
        
        switch cellType {
        case .threeGrid:
            let size = (fullWidth / 3) - 15
            return CGSize(width: size, height: size)
        case .twoGrid:
            let size = (fullWidth / 2) - 15
            return CGSize(width: size, height: size)
        case .table:
            let width = (fullWidth - 15)
            let height = (fullWidth / 2) - 15
            return CGSize(width: width, height: height)
        case .full:
            let width = (fullWidth - 15)
            let height = (fullHeight - 15)
            return CGSize(width: width, height: height)
        case .list:
            let width = (fullWidth - 15)
            let height = (fullHeight - 15)
            
            if let myCollectionView = myCollectionView,
               let cell = myCollectionView.cellForItem(at: indexPath) {
                
                let dynamicSize = cell.systemLayoutSizeFitting(CGSize(width: width,
                                                                      height: UIView.layoutFittingExpandedSize.height),
                                                               withHorizontalFittingPriority: .required,
                                                               verticalFittingPriority: .fittingSizeLevel)
                
                let dynamicHeight = height < dynamicSize.height ? height : dynamicSize.height
                
                return CGSize(width: width, height: dynamicHeight)
            } else {
                return CGSize(width: width, height: height)
            }
        }
    }
    
    // 셀 여백
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        
        return UIEdgeInsets(top: 10, left: 10, bottom: 10, right: 10)
    }
    
    // 헤더 사이즈
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForHeaderInSection section: Int) -> CGSize {
        let width = collectionView.bounds.width
        
        if isSelectionMode {
            return CGSize(width: width, height: 50)
        } else {
            return CGSize(width: width, height: 1)
        }
    }
    
    // 푸터 사이즈
    // 동적으로 크기를 조정하는 방법
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForFooterInSection section: Int) -> CGSize {
        let width = collectionView.bounds.width
        
        let indexPath = IndexPath(row: 0, section: section)
        guard let footerView = collectionView.supplementaryView(forElementKind: UICollectionView.elementKindSectionFooter, at: indexPath) else {
            print(#fileID, #function, #line, "-footer dynamic ")
            return CGSize(width: width, height: 100)
        }
        
        return footerView.systemLayoutSizeFitting(CGSize(width: collectionView.frame.width, height: UIView.layoutFittingExpandedSize.height),
                                                  withHorizontalFittingPriority: .required,
                                                  verticalFittingPriority: .fittingSizeLevel)
    }
}

// MARK: - ScrollViewDelegate
extension MyCollectionViewDataSource : UIScrollViewDelegate {
    
    // Offset(Y)지점이 ScrollView의 Bottom에 닿은지 체크하기 위해, 여러번 호출되기 때문에 변수를 만들어서 다중호출 차단
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        
        guard isBottomCheck(scrollView),
              !isFetchingMore else { return }
        
        isFetchingMore = true
        
        print(#fileID, #function, #line, "-scroll tset : bottom ")
        
        self.footerApplyState(CustomFooterView.State.fetchingMore)
        
        // 받아올 데이터가 있는 상황에선 자연스럽게 지연시간이 발생됨
        // 받올 데이터가 없는 상황에선 지연시간이 거의 없다.
        // 이 때, 추가로 지연시간을 두지 않았을 땐 isFetchingMore가 false가 되는 타이밍이 scrollViewDidScroll 다중호출이 되는 시점보다 빨라서 !isFetchingMore가 제대로 작동되지 않음
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            self.fetchMoreGifList { [weak self] in
                self?.isFetchingMore = false
                print(#fileID, #function, #line, "-scroll test : end")
            }
        }
    }
    
    func scrollViewWillEndDragging(_ scrollView: UIScrollView, withVelocity velocity: CGPoint, targetContentOffset: UnsafeMutablePointer<CGPoint>) {
        if cellType == .full {
            if let myCollectionView = myCollectionView {
                myCollectionView.verticalSnapToItem(targetContentOffset: targetContentOffset, scrollView: scrollView, velocity: velocity)
            }
        }
    }
    
}

// MARK: - Helper
extension MyCollectionViewDataSource {
    /// 스크롤뷰 바텀에 닿은지 체크
    /// - Parameters:
    ///   - threshold: 임계점(여유를 얼만큼 둘 것인지)
    /// - Returns: 체크여부
    fileprivate func isBottomCheck(threshold: CGFloat = -50.0 , _ scrollView: UIScrollView) -> Bool {
        
        let contentSize = scrollView.contentSize.height
        
        let scrollViewSize = scrollView.frame.size.height
        
        print(#fileID, #function, #line, "contentSize: \(contentSize), scrollViewSize: \(scrollViewSize) ")
        
        if contentSize < scrollViewSize {
            return false
        }
        
        let bottomEdge = scrollView.contentOffset.y + scrollView.frame.size.height
        
        let isBottom = bottomEdge + threshold >= scrollView.contentSize.height
        
        return isBottom
    }
}
