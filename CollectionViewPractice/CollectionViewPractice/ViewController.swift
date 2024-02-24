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
    
    var gifOffset: Int = 0
    
    var fetchLimit : Int = 12
    
    var isFetchingMore : Bool = false
    
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
    
    
    /// gif api 통신
    /// - Parameters:
    ///   - offset: 시작지점
    ///   - limit: 가져올 갯수
    ///   - completion: 끝난 시점에 [URL]을 출력
    func fetchGiphyResponse(offset: Int = 0,
                            limit: Int = 12,
                            completion: (([URL]) -> Void)? = nil ) {
        let url = URL(string: "https://api.giphy.com/v1/gifs/trending?api_key=3fMEvHqxzTsVYZoymezAoiC1CARul24N&offset=\(offset)&limit=\(limit)")!
        
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
    
    
    /// gif 가져오기
    /// - Parameter completion: 가져온 시점
    fileprivate func loadGif(completion: (() -> Void)? = nil) {
        fetchGiphyResponse { [weak self] urlList in
            self?.gifList = urlList
            
            DispatchQueue.main.async {
                self?.myCollectionView.reloadData()
            }
            
            completion?()
        }
    }
    
    
    /// gif 더 가져오기
    fileprivate func fetchMoreGifList(completion: (() -> Void)? = nil ) {
        let fetchOffset = gifOffset + fetchLimit
        print(#fileID, #function, #line, "-fetchOffset : \(fetchOffset) ")
        
        fetchGiphyResponse(offset: fetchOffset) { [weak self] urlList in
            
            guard let self = self else { return }
            
            self.gifOffset += self.fetchLimit
            
            insertItemsInCollectionView(urlList, self)
            completion?()
        }
    }
}

// MARK: - 콜렉션뷰 UI 업데이트 관련
extension ViewController {
    fileprivate func insertItemsInCollectionView(_ urlList: [URL], _ self: ViewController) {
        let appendingIndexPathList: [IndexPath] = urlList
            .enumerated()
            .map { (index, element) in
                let startPoint = self.gifList.count + index
                
                return IndexPath(item: startPoint, section: 0)
            }
        
        self.gifList.append(contentsOf: urlList)
        
        DispatchQueue.main.async {
            self.myCollectionView.insertItems(at: appendingIndexPathList)
        }
    }
}

// MARK: - Nav
extension ViewController {
    
    fileprivate func configureNav() {
        self.navigationItem.leftBarButtonItem = UIBarButtonItem(title: selectionModeInfo, style: .plain, target: self, action: #selector(selectMode))
        
        self.navigationItem.rightBarButtonItem = UIBarButtonItem(title: "더 가져오기", style: .plain, target: self, action: #selector(fetchMore))
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
    
    @objc func fetchMore() {
        fetchMoreGifList()
    }
}

// MARK: - Helper
extension ViewController {
    
    
    /// 스크롤뷰 바텀에 닿은지 체크
    /// - Parameters:
    ///   - threshold: 임계점(여유를 얼만큼 둘 것인지)
    /// - Returns: 체크여부
    fileprivate func isBottomCheck(threshold: CGFloat = 300, _ scrollView: UIScrollView) -> Bool {
        
        let contentSize = scrollView.contentSize.height
        
        let scrollViewSize = scrollView.frame.height
        
        if contentSize >= scrollViewSize {
            return false
        }
        
        let bottomEdge = scrollView.contentOffset.y + scrollView.frame.size.height
        
        let isBottom = bottomEdge >= scrollView.contentSize.height
        
        return isBottom
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

extension ViewController: UIScrollViewDelegate {
    
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        
        guard isBottomCheck(scrollView),
              !isFetchingMore else { return }
        
        isFetchingMore = true
        
        self.fetchMoreGifList { [weak self] in
            self?.isFetchingMore = false
        }
        
    }
}





