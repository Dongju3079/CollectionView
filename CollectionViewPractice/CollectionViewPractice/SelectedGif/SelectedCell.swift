//
//  SelectedCell.swift
//  CollectionViewPractice
//
//  Created by Macbook on 2/27/24.
//

import UIKit
import SwiftyGif

// 약한 참조를 걸어주기 위해선 AnyObject가 필요함
protocol GifSelectionDelegate: AnyObject {
    func deSelected(cellData: String)
}

class SelectedCell: UICollectionViewCell {
    
    @IBOutlet weak var selectedGif: UIImageView!
    @IBOutlet weak var deSelectedBT: UIButton!
    
    weak var delegate: GifSelectionDelegate?
    var cellData: String?
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        self.selectedGif.layer.cornerRadius = 8
        self.selectedGif.layer.borderWidth = 3
        self.selectedGif.layer.borderColor = UIColor.black.withAlphaComponent(0.5
        ).cgColor
        
        self.deSelectedBT.addTarget(self, action: #selector(deSelectedAction), for: .touchUpInside)
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        print(#fileID, #function, #line, "- ")
        self.selectedGif.clear()
    }
    
    func configureCell(cellData: String, delegate: GifSelectionDelegate) {
        
        self.delegate = delegate
        self.cellData = cellData
        
        if let url = URL(string: cellData) {
            let loader = UIActivityIndicatorView(style: .medium)
            self.selectedGif.setGifFromURL(url, customLoader: loader)
        }
    }
    
    @objc func deSelectedAction(_ sender: UIButton) {
        if let cellData = cellData {
            self.delegate?.deSelected(cellData: cellData)
        }
    }
}
