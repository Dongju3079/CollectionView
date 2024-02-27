//
//  CustomFooterView.swift
//  CollectionViewPractice
//
//  Created by Macbook on 2/24/24.
//

import UIKit

class CustomFooterView: UICollectionReusableView {
        
    @IBOutlet weak var footerLabel: UILabel!
    
    @IBOutlet weak var loadingView: UIActivityIndicatorView!
    
    enum State {
        case normal
        case fetchingMore
        case noMore
        
        var info: String {
            switch self {
            case .normal: return ""
            case .fetchingMore: return "데이터를 받아오고 있습니다."
            case .noMore : return "추가로 받아올 데이터가 없습니다."
            }
        }
    }
    
    func applyState(state: State) {
        
        self.footerLabel.text = state.info
        
        if case .fetchingMore = state {
            self.loadingView.isHidden = false
        } else {
            self.loadingView.isHidden = true
        }
    }
    
    
    
    override func awakeFromNib() {
        super.awakeFromNib()
        print(#fileID, #function, #line, "- ")
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        print(#fileID, #function, #line, "- ")
    }
}
