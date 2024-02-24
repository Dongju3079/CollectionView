//
//  ViewController.swift
//  CollectionViewPractice
//
//  Created by Macbook on 2/24/24.
//

import UIKit

class ViewController: UIViewController {

    @IBOutlet weak var myCollectionView: UICollectionView!
    
    var gifList: [String] = ["123","123","123","123","123","123","123","123","123","123","123","123","123","123","123","123","123","123","123","123","123","123","123","123","123","123","123","123","123","123","123","123","123","123","123","123","123","123","123","123","123","123","123","123"]
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        myCollectionView.dataSource = self
        myCollectionView.delegate = self
        myCollectionView.collectionViewLayout = UICollectionViewFlowLayout()
    }
    
}

extension ViewController: UICollectionViewDataSource {
    
    // 컬렉션 뷰 갯수
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return self.gifList.count
    }
    
    // 컬렉션 뷰 셀 구성
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: CustomCollectionViewCell.reuseIdentifier, for: indexPath)
        
        return cell
    }
    
    // 컬렉션 뷰 헤더, 푸터 뷰 구성
    func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        
        switch kind {
        case UICollectionView.elementKindSectionHeader:
            let headerView = collectionView.dequeueReusableSupplementaryView(ofKind: UICollectionView.elementKindSectionHeader, withReuseIdentifier: CustomHeaderView.reuseIdentifier, for: indexPath)
            return headerView
        default:
            let footerView = collectionView.dequeueReusableSupplementaryView(ofKind: UICollectionView.elementKindSectionFooter, withReuseIdentifier: CustomFooterView.reuseIdentifier, for: indexPath)
            return footerView
        }
        
    }
}

extension ViewController: UICollectionViewDelegateFlowLayout {
    
    // 셀 크기
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        
        let width = (collectionView.bounds.width / 3) - 15
        
        return CGSize(width: width, height: width)
    }
    
    // 셀 여백
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        return UIEdgeInsets(top: 10, left: 10, bottom: 10, right: 10)
    }
    
    // 헤더 사이즈
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForHeaderInSection section: Int) -> CGSize {
        let width = collectionView.bounds.width
        
        return CGSize(width: width, height: 100)
    }
    
    // 푸터 사이즈
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForFooterInSection section: Int) -> CGSize {
        let width = collectionView.bounds.width
        
        return CGSize(width: width, height: 100)
    }
    
}



