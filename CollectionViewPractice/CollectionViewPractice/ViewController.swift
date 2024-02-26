//
//  ViewController.swift
//  CollectionViewPractice
//
//  Created by Macbook on 2/24/24.
//

import UIKit

class ViewController: UIViewController {

    enum CellType : Int {
        case threeGrid = 0
        case twoGrid
        case table
        case full
    }
    
    @IBOutlet weak var myCollectionView: UICollectionView!
    
    @IBOutlet weak var segControl: UISegmentedControl!
    
    let reloadController: UIRefreshControl = UIRefreshControl()
    
    var selectedGifList: Set<String> = []
    
    var gifOffset: Int = 0
    
    var fetchLimit : Int = 18
    
    var isFetchingMore : Bool = false
    
    var isFetchingButtonClicked: Bool = false
    
    var footerState : CustomFooterView.State = .normal
    
    var cellType: CellType = .threeGrid
    
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
        setSegControl()
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
                                              completionHandler: { [weak self] data, response, err in
            
            guard let self = self else { return }
            
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
    
    // UIRefresh 활용해보기(sender 숙지)
    @objc func reload(_ sender: UIRefreshControl) {
        loadGif {
            DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                sender.endRefreshing()
            }
        }
    }
}

// MARK: - 콜렉션뷰 UI 업데이트 관련
extension ViewController {
    
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
    
    // collectionView.collectionViewLayout.invalidateLayout() : 컬렉션뷰 자체의 레이아웃을 업데이트(셀은 간섭받지 않는다.)
    fileprivate func footerApplyState(state: CustomFooterView.State) {
        print(#fileID, #function, #line, "-customFooterState ")
        
        self.footerState = state
        
        DispatchQueue.main.async { [weak self] in
            
            guard let self = self else { return print(#fileID, #function, #line, "-nothing self ")}
            
            let footer = self.myCollectionView.visibleSupplementaryViews(ofKind: UICollectionView.elementKindSectionFooter)
            
            if let sectionFooter = footer.first(where: { $0.isKind(of: CustomFooterView.self) }) as? CustomFooterView {
                sectionFooter.applyState(state: state)
            }
            
            self.myCollectionView.collectionViewLayout.invalidateLayout()
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
        self.isSelectionMode.toggle()
        sender.title = self.selectionModeInfo
        
        self.myCollectionView.performBatchUpdates { [weak self] in
            print(#fileID, #function, #line, "- ")
            let indexSet = IndexSet(integer: 0)
            
            // header의 height 크기를 조절해서 선택에 따라서 보이게끔 설정
            self?.myCollectionView.reloadSections(indexSet)
        }
    }

    @objc func fetchMore(_ sender: UIBarButtonItem) {
        
        if !isSelectionMode || selectedGifList.isEmpty {
            let message = "1. 선택모드 ON\n2. 체크박스 클릭"
            self.presentAlert("공유하기", message)
            return
        }
        
        let gifShard = Array(selectedGifList)
        let ac = UIActivityViewController(activityItems: gifShard, applicationActivities: nil)
        self.present(ac, animated: true)
    }
}

// MARK: - Seg
extension ViewController {
    fileprivate func setSegControl() {
        self.segControl.addTarget(self, action: #selector(changeCellSize), for: .valueChanged)
    }
    
    @objc func changeCellSize(_ sender: UISegmentedControl) {
        
        self.cellType = CellType(rawValue: sender.selectedSegmentIndex) ?? CellType.threeGrid
        
        self.myCollectionView.performBatchUpdates {
            let indexSet = IndexSet(integer: 0)
            self.myCollectionView.reloadSections(indexSet)
        }
    }
}

// MARK: - Helper
extension ViewController {
    
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

// MARK: - Configure Cell
extension ViewController: UICollectionViewDataSource {
    
    // 컬렉션 뷰 갯수
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return self.gifList.count
    }
    
    // cell에 선택모드인지, 선택된 셀인지에 대한 정보를 전달
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
            
            if let footerView = footerView as? CustomFooterView {
                footerView.applyState(state: self.footerState)
            }
            
            return footerView
        }
        
    }
}

extension ViewController: UICollectionViewDelegate {
    
    // 선택이 되기 전 (선택되게 할 것인지에 대한 Bool)
    func collectionView(_ collectionView: UICollectionView, shouldSelectItemAt indexPath: IndexPath) -> Bool {
        return self.isSelectionMode
    }
    
    // header에 접근하기
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
        
        let fullWidth = myCollectionView.bounds.width
        let fullHeight = myCollectionView.bounds.height
        
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
            return CGSize(width: width, height: 0)
        }
    }
    
    // 푸터 사이즈
    // 동적으로 크기를 조정하는 방법
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForFooterInSection section: Int) -> CGSize {
        let width = collectionView.bounds.width
        
        // Get the view for the first header
        let indexPath = IndexPath(row: 0, section: section)
        guard let footerView = collectionView.supplementaryView(forElementKind: UICollectionView.elementKindSectionFooter, at: indexPath) else {
            print(#fileID, #function, #line, "-footer dynamic ")
            return CGSize(width: width, height: 100)
        }
        
        // Use this view to calculate the optimal size based on the collection view's width
        return footerView.systemLayoutSizeFitting(CGSize(width: collectionView.frame.width, height: UIView.layoutFittingExpandedSize.height),
                                                  withHorizontalFittingPriority: .required, // Width is fixed
                                                  verticalFittingPriority: .fittingSizeLevel) // Height can be as large as needed
        
    }
    
}

extension ViewController: UIScrollViewDelegate {
        
    // Offset(Y)지점이 ScrollView의 Bottom에 닿은지 체크하기 위해, 여러번 호출되기 때문에 변수를 만들어서 다중호출 차단
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        
        guard isBottomCheck(scrollView),
              !isFetchingMore else { return }
        
        isFetchingMore = true
        
        print(#fileID, #function, #line, "-scroll tset : bottom ")
        
        self.footerApplyState(state: CustomFooterView.State.fetchingMore)
        
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
            self.myCollectionView.verticalSnapToItem(targetContentOffset: targetContentOffset, scrollView: scrollView, velocity: velocity)
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




