//
//  UIColletionView+Snap.swift
//  CollectionViewPractice
//
//  Created by Macbook on 2/27/24.
//

import Foundation
import UIKit

// MARK: - snaping 처리
extension UICollectionView {
    
    func verticalSnapToItem(targetContentOffset: UnsafeMutablePointer<CGPoint>,
                            scrollView: UIScrollView,
                            velocity: CGPoint){
        
        // 기준점을 scrollView의 content의 offset으로 두고
        targetContentOffset.pointee = scrollView.contentOffset
        
        // 화면에 표시되는 item의 indexPath 배열
        var indexPaths = self.indexPathsForVisibleItems
        
        // 랜덤으로 들어오게 되어 오름차순이 아님
        indexPaths.sort()
        
        // 가장 첫번째로 넣고
        var indexPath = indexPaths.first!
        
        // 가속도가 0보다 크다면
        if velocity.y > 0{
            indexPath.item += 1
        } else if velocity.y == 0{
            
            // indexPath값을 이용해 cell을 가져온다.
            let cell = self.cellForItem(at: indexPath)!
            
            // self.contentOffset.y : 상단을 기준으로 y위치
            // cell.frame.origin.y : 상단을 기준으로 셀의 시작위치
            // 셀의 Inset이 얼만큼 거리가 있는지 모르니 (-)
            let position = self.contentOffset.y - cell.frame.origin.y
            
            // 셀을 가장 윗부분(y)가 중간을 넘어서면 + 1 그렇지 않다면 원래 값
            if position > cell.frame.size.height / 2 {
                indexPath.item += 1
            }
        }
        
        // -가 없는데 되돌아 갈 수 있는 이유?
        // indexPaths에는 현재 화면에 보이는 indexPath가 담기게 됨
        // 되돌아 가려고 하는 순간 윗 셀도 담기게 됨
        // 고로 + 1이 되지 않는다면 first 로 돌아가게 됨
        
        self.scrollToItem(at: indexPath, at: .centeredVertically, animated: true )
    }
}




