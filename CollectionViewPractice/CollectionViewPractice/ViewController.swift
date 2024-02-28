//
//  ViewController.swift
//  CollectionViewPractice
//
//  Created by Macbook on 2/24/24.
//

import UIKit

class ViewController: UIViewController {
    
    // MARK: - UI Components
    @IBOutlet weak var myCollectionView: UICollectionView!
    
    @IBOutlet weak var segControl: UISegmentedControl!
    
    @IBOutlet weak var selectedCollectionView: UICollectionView!
    
    let reloadController: UIRefreshControl = UIRefreshControl()

    // MARK: - Variables
    var gifList: [URL] = [] {
        didSet {
            myCollectionViewDataSource.gifList = gifList
            DispatchQueue.main.async {
                let count = self.gifList.count
                self.navigationItem.title = "가져온 GIF : \(count)"
            }
        }
    }
    
    var selectedGifList: [String] = [] {
        didSet {
            myCollectionViewDataSource.selectedGifList = selectedGifList
            selectedCollectionViewDataSource.setData(newData: selectedGifList)
            
            updateHeaderView(myCollectionView)
            handleSelectedCollectionViewVisibility(isHidden: self.selectedGifList.count < 1)
        }
    }
    
    let selectedCollectionViewDataSource : SelectedGifDataSource = SelectedGifDataSource()
    let myCollectionViewDataSource: MyCollectionViewDataSource = MyCollectionViewDataSource()
    
    var gifOffset: Int = 0
    
    var fetchLimit : Int = 18
                
    var selectionModeInfo: String {
        return myCollectionViewDataSource.isSelectionMode ? "선택모드 ON" : "선택모드 OFF"
    }
    
    // MARK: - LifeCycle
    override func viewDidLoad() {
        super.viewDidLoad()
        
        configureColletionView()
        loadGif()
        configureNav()
        setSegControl()
    }
}

// MARK: - ColletionView
extension ViewController {
    fileprivate func configureColletionView() {
        
        // MARK: - gifColletionView Setup
        myCollectionViewDataSource.configureDataSource(myCollectionView)
        
        // MARK: - gifCollectionView Closure Setup
        myCollectionViewDataSource.insertSelectedGifList = insertSelectedGifList(_:)
        myCollectionViewDataSource.updateHeaderView = updateHeaderView(_:)
        myCollectionViewDataSource.fetchMoreGifList = fetchMoreGifList(completion:)
        myCollectionViewDataSource.footerApplyState = footerApplyState(state:)
        
        // MARK: - selectedCollectionView Setup
        selectedCollectionViewDataSource.configureDataSource(selectedCollectionView, self)

    }
}

// MARK: - 콜렉션뷰 UI 업데이트 관련
extension ViewController {
    // collectionView.collectionViewLayout.invalidateLayout() : 컬렉션뷰 자체의 레이아웃을 업데이트(셀은 간섭받지 않는다.)
    func footerApplyState(state: CustomFooterView.State) {
        print(#fileID, #function, #line, "-customFooterState ")
        
        self.myCollectionViewDataSource.footerState = state
        
        DispatchQueue.main.async { [weak self] in
            
            guard let self = self else { return }
            
            let footer = myCollectionView.visibleSupplementaryViews(ofKind: UICollectionView.elementKindSectionFooter)
            
            if let sectionFooter = footer.first(where: { $0.isKind(of: CustomFooterView.self) }) as? CustomFooterView {
                sectionFooter.applyState(state: state)
            }
            
            myCollectionView.collectionViewLayout.invalidateLayout()
        }
    }
    
    // 받아온 데이터 배열을 enumerated를 활용해서 번호 붙여주기 (point: 실제배열에는 enumerated 작업 후에 추가했음 why? IndexPath 생성할 때 추가되기 전 count가 필요하기에)
    fileprivate func insertItemsInCollectionView(_ urlList: [URL], _ self: ViewController, completion: (() -> Void)? = nil ) {
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
        
        completion?()
    }
    
    /// 헤더뷰 텍스트 업데이트
    /// - Parameter collectionView:
    fileprivate func updateHeaderView(_ collectionView: UICollectionView) {
        
        let header = collectionView.visibleSupplementaryViews(ofKind: UICollectionView.elementKindSectionHeader)
        
        if let sectionHeader = header.first(where: { $0.isKind(of: CustomHeaderView.self) }) as? CustomHeaderView {
            
            sectionHeader.selectionInfoLabel.text = "선택된 Gif : \(self.selectedGifList.count)개"
        }
    }
    
    
    /// 헤더뷰 hidden 처리
    /// - Parameter isHidden:
    fileprivate func handleSelectedCollectionViewVisibility(isHidden: Bool) {
        DispatchQueue.main.async {
            UIView.transition(with: self.view, duration: 0.2,
                              options: .curveEaseIn,
                              animations: { [weak self] in
                guard let self = self else { return }
                
                self.selectedCollectionView.isHidden = isHidden
            })
        }
    }
}

// MARK: - Nav
extension ViewController {
    
    fileprivate func configureNav() {
        self.navigationItem.leftBarButtonItem = UIBarButtonItem(title: selectionModeInfo, style: .plain, target: self, action: #selector(selectMode))
        
        self.navigationItem.rightBarButtonItem = UIBarButtonItem(title: "공유하기", style: .plain, target: self, action: #selector(fetchMore))
    }
    
    // performBatchUpdates를 활용한 animation 효과
    @objc func selectMode(_ sender: UIBarButtonItem) {
        // dataSource
        self.myCollectionViewDataSource.isSelectionMode.toggle()
        sender.title = self.selectionModeInfo
        
        self.myCollectionView.performBatchUpdates { [weak self] in
            print(#fileID, #function, #line, "- ")
            let indexSet = IndexSet(integer: 0)
            
            // header의 height 크기를 조절해서 선택에 따라서 보이게끔 설정
            self?.myCollectionView.reloadSections(indexSet)
        }
    }

    @objc func fetchMore(_ sender: UIBarButtonItem) {
        
        if !self.myCollectionViewDataSource.isSelectionMode || selectedGifList.isEmpty {
            let message = "1. 선택모드 ON\n2. 체크박스 클릭"
            self.presentAlert("공유하기", message)
            return
        }
        
        let gifShard = Array(selectedGifList)
        let ac = UIActivityViewController(activityItems: gifShard, applicationActivities: nil)
        self.present(ac, animated: true)
    }
}

// MARK: - refresh
extension ViewController {
    fileprivate func setRefresh() {
        myCollectionView.refreshControl = self.reloadController
        reloadController.addTarget(self, action: #selector(reload), for: .valueChanged)
    }
    
    // UIRefresh 활용해보기(sender 숙지)
    @objc func reload(_ sender: UIRefreshControl) {
        loadGif {
            DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                sender.endRefreshing()
            }
        }
    }
}

// MARK: - Seg
extension ViewController {
    fileprivate func setSegControl() {
        self.segControl.addTarget(self, action: #selector(changeCellSize), for: .valueChanged)
    }
    
    @objc func changeCellSize(_ sender: UISegmentedControl) {
        
        let cellType = MyCollectionViewDataSource.CellType.self
        
        myCollectionViewDataSource.cellType = cellType.init(rawValue: sender.selectedSegmentIndex) ?? cellType.threeGrid
        
        self.myCollectionView.performBatchUpdates {
            let indexSet = IndexSet(integer: 0)
            self.myCollectionView.reloadSections(indexSet)
        }
    }
}

// MARK: - API
extension ViewController {
    /// gif api 통신
    /// - Parameters:
    ///   - offset: 시작지점
    ///   - limit: 가져올 갯수
    ///   - completion: 끝난 시점에 [URL]을 출력
    func fetchGiphyResponse(offset: Int = 0,
                            limit: Int = 18,
                            completion: (([URL]?, Pagination?, Error?) -> Void)? = nil ) {
        
        guard let url = URL(string: "https://api.giphy.com/v1/gifs/trending?api_key=3fMEvHqxzTsVYZoymezAoiC1CARul24N&offset=\(offset)&limit=\(limit)") else {
            completion?(nil, nil, MyError.notAllowedURL)
            return
        }
        
        let task = URLSession.shared.dataTask(with: url,
                                              completionHandler: { data, response, err in
            
            if err != nil {
                completion?(nil, nil, MyError.unKnownErr(err))
                return
            }
            
            guard let data: Data = data else {
                completion?(nil, nil, MyError.noData)
                return
            }
            
            guard let httpUrlResponse = response as? HTTPURLResponse else {
                completion?(nil, nil, MyError.unKnownErr(err))
                return
            }
            
            let statusCode = httpUrlResponse.statusCode
            
            if 400...499 ~= statusCode  {
                let response: GiphyResponse? = try? JSONDecoder().decode(GiphyResponse.self, from: data)
                completion?(nil, nil, MyError.unAuthorized(response))
                return
            }
            
            do {
                let giphyResponse : GiphyResponse = try JSONDecoder().decode(GiphyResponse.self, from: data)
                
                if let pagination = giphyResponse.pagination,
                   let giphyList : [Giphy] = giphyResponse.data {
                    
                    let urlList : [URL] = giphyList.compactMap { giphy in
                        giphy.getUrl()
                    }
                    completion?(urlList, pagination, nil)
                }
            } catch {
                completion?(nil, nil, MyError.decodingErr)
            }
            
        })
        task.resume()
    }
    
    /// gif 가져오기
    /// - Parameter completion: 가져온 시점
    fileprivate func loadGif(completion: (() -> Void)? = nil) {
        fetchGiphyResponse { [weak self] urlList, pagination, error in
            if error != nil {
                self?.errHandler(error)
                return
            }
            
            guard let self = self,
                  let urlList = urlList,
                  let pagination = pagination else { return }
            
            self.gifList = urlList
            
            let state = pagination.checkEnd() ? CustomFooterView.State.noMore : CustomFooterView.State.normal
            
            // DispatchQueue.main.async도 약간의 시간이 걸리는 것 같음
            DispatchQueue.main.async {
                self.myCollectionView.reloadData()
                self.footerApplyState(state: state)
            }
            
            completion?()
        }
    }
    
    // offset을 활용한 데이터 추가로 가져오기
    /// gif 더 가져오기
    fileprivate func fetchMoreGifList(completion: (() -> Void)? = nil ) {
        let fetchOffset = gifOffset + fetchLimit
        
        fetchGiphyResponse(offset: fetchOffset) { [weak self] urlList, pagination, error in
            
            print(#fileID, #function, #line, "-fetchOffset: \(fetchOffset) ")
            
            if error != nil {
                self?.errHandler(error)
                return
            }
            
            guard let self = self,
                  let urlList = urlList,
                  let pagination = pagination else { return }
            
            insertItemsInCollectionView(urlList, self) {
                
                if pagination.checkEnd() {
                    self.footerApplyState(state: .noMore)
                } else {
                    self.footerApplyState(state: .normal)
                    self.gifOffset = fetchOffset
                }
            }
            
            completion?()
        }
    }
}

// MARK: - 에러처리
extension ViewController {
    
    fileprivate func errHandler(_ err: Error?) {
    
        if let err = err as? MyError {
            DispatchQueue.main.async {
                let alert = UIAlertController(title: "에러", message: err.info, preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: NSLocalizedString("확인", comment: "Default action"), style: .default, handler: { _ in
                NSLog("The \"OK\" alert occured.")
                }))
                self.present(alert, animated: true, completion: nil)
            }
        }
    }
}

// MARK: - Helper
extension ViewController {
    
    /// 셀 선택시 추가 및 제거
    /// - Parameter indexPath: 셀 indexPath
    fileprivate func insertSelectedGifList(_ indexPath: IndexPath) {
        let selectedUrlString = self.gifList[indexPath.item].absoluteString
        
        if selectedGifList.contains(selectedUrlString) {
            
            if let deletedIndex = selectedGifList.firstIndex(where: { $0 == selectedUrlString }) {
                selectedGifList.remove(at: deletedIndex)
            }
            
        } else {
            selectedGifList.insert(selectedUrlString, at: 0)
        }
    }
}

// MARK: - alert
extension ViewController {
    fileprivate func presentAlert(_ title: String = "안내", _ text: String) {
        DispatchQueue.main.async { [weak self] in
            let alert = UIAlertController(title: title, message: text, preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: NSLocalizedString("확인", comment: "Default action"), style: .default, handler: { _ in
                NSLog("The \"OK\" alert occured.")
            }))
            self?.present(alert, animated: true, completion: nil)
        }
    }
}

// MARK: - delegate
extension ViewController: GifSelectionDelegate {
    
    func deSelected(cellData: String) {
        print(#fileID, #function, #line, "- ")
        
        if let deletedIndex = selectedGifList.firstIndex(where: { $0 == cellData }) {
            selectedGifList.remove(at: deletedIndex)
        }
        
        if let deSelectedIndex = gifList.firstIndex(where: { $0.absoluteString == cellData }) {
            let reloadIndex = IndexPath(item: deSelectedIndex, section: 0)
            myCollectionView.reloadItems(at: [reloadIndex])
        }
    }
}
