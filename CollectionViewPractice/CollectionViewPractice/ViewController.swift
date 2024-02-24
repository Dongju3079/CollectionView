//
//  ViewController.swift
//  CollectionViewPractice
//
//  Created by Macbook on 2/24/24.
//

import UIKit
import SwiftyGif

class ViewController: UIViewController {

    @IBOutlet weak var myCollectionView: UICollectionView!
    
    let reloadController: UIRefreshControl = UIRefreshControl()
    
    var selectedGifList: Set<String> = []
    
    var gifList: [URL] = [] {
        didSet {
            DispatchQueue.main.async {
                let count = self.gifList.count
                self.navigationItem.title = "가져온 움짤 : \(count)"
            }
        }
    }
    
    var isSelectionMode: Bool = false
    
    var selectionModeInfo: String {
        return isSelectionMode ? "선택모드 ON" : "선택모드 OFF"
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        myCollectionView.dataSource = self
        myCollectionView.delegate = self
        myCollectionView.collectionViewLayout = UICollectionViewFlowLayout()
        myCollectionView.refreshControl = self.reloadController
        reloadController.addTarget(self, action: #selector(reload), for: .valueChanged)
        loadGif()
        configureNav()
    }
    
    fileprivate func configureNav() {
        self.navigationItem.leftBarButtonItem = UIBarButtonItem(title: selectionModeInfo, style: .plain, target: self, action: #selector(selectMode))
    }
    
    @objc func selectMode(_ sender: UIBarButtonItem) {
        self.isSelectionMode.toggle()
        sender.title = self.selectionModeInfo
        
        self.myCollectionView.performBatchUpdates { [weak self] in
            print(#fileID, #function, #line, "- ")
            let indexSet = IndexSet(integer: 0)
            
            self?.myCollectionView.reloadSections(indexSet)
        }
    }
    
}

// API 관련
extension ViewController {
    @objc func reload(_ sender: UIRefreshControl) {
        loadGif {
            DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                sender.endRefreshing()
            }
        }
    }
    
    func fetchGiphyResponse(completion: (([URL]) -> Void)? = nil ) {
        let url = URL(string: "https://api.giphy.com/v1/gifs/trending?api_key=3fMEvHqxzTsVYZoymezAoiC1CARul24N")!
        
        let task = URLSession.shared.dataTask(with: url,
                                              completionHandler: { [weak self] data, response, err in
            
            guard let self = self else { return }
            
            if err != nil {
                return
            }
            
            guard let data: Data = data else { return }
            
            if let giphyResponse : GiphyResponse = try? JSONDecoder().decode(GiphyResponse.self, from: data),
               let giphyList : [Giphy] = giphyResponse.data {
                
                let urlList : [URL] = giphyList.compactMap { giphy in
                    giphy.getUrl()
                }
                
                completion?(urlList)
                
                print(#fileID, #function, #line, "-gif count : \(self.gifList.count) ")
            }
            
        })
        task.resume()
    }
    
    fileprivate func loadGif(completion: (() -> Void)? = nil) {
        fetchGiphyResponse { [weak self] urlList in
            self?.gifList = urlList
            
            DispatchQueue.main.async {
                self?.myCollectionView.reloadData()
            }
            
            completion?()
        }
    }
}

extension ViewController: UICollectionViewDataSource {
    
    // 컬렉션 뷰 갯수
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return self.gifList.count
    }
    
    // 컬렉션 뷰 셀 구성
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: CustomCollectionViewCell.reuseIdentifier, for: indexPath) as? CustomCollectionViewCell else { return UICollectionViewCell() }
        
        let url = self.gifList[indexPath.item]
        cell.configureCell(cellData: url, isSelectionMode: self.isSelectionMode, selectedGifList: self.selectedGifList)
        
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

extension ViewController: UICollectionViewDelegate {
    
    func collectionView(_ collectionView: UICollectionView, shouldSelectItemAt indexPath: IndexPath) -> Bool {
        return self.isSelectionMode
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        print(#fileID, #function, #line, "- ")
        
        let selectedUrlString = self.gifList[indexPath.item].absoluteString
        
        if selectedGifList.contains(selectedUrlString) {
            selectedGifList.remove(selectedUrlString)
        } else {
            selectedGifList.insert(selectedUrlString)
        }
        
        collectionView.reloadItems(at: [indexPath])
        
        let header = collectionView.visibleSupplementaryViews(ofKind: UICollectionView.elementKindSectionHeader)
        
        if let sectionHeader = header.first(where: { $0.isKind(of: CustomHeaderView.self) }) as? CustomHeaderView {
            sectionHeader.selectionInfoLabel.text = "선택된 Gif : \(self.selectedGifList.count)개"
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
        
        if isSelectionMode {
            return CGSize(width: width, height: 50)
        } else {
            return CGSize(width: width, height: 0)
        }
    }
    
    // 푸터 사이즈
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForFooterInSection section: Int) -> CGSize {
        let width = collectionView.bounds.width
        
        return CGSize(width: width, height: 100)
    }
    
}



