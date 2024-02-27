//
//  CustomCollectionViewCell.swift
//  CollectionViewPractice
//
//  Created by Macbook on 2/24/24.
//

import UIKit
import SwiftyGif

class CustomCollectionViewCell: UICollectionViewCell {
    
    @IBOutlet weak var gifView: UIImageView!
    
    @IBOutlet weak var selectBox: UIImageView!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        print(#fileID, #function, #line, "- ")
        
        self.contentView.layer.cornerRadius = 8
        self.contentView.layer.borderWidth = 3
        self.contentView.layer.borderColor = UIColor.black.withAlphaComponent(0.5
        ).cgColor
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        print(#fileID, #function, #line, "- ")
        self.gifView.image = nil
        self.gifView.clear()
    }
    
    func configureCell(cellData: URL,
                       isSelectionMode: Bool,
                       selectedGifList: [String]) {
        let loader = UIActivityIndicatorView(style: .medium)
        self.gifView.setGifFromURL(cellData, customLoader: loader)
        
        self.selectBox.isHidden = !isSelectionMode
        
        let isSelected = selectedGifList.contains(cellData.absoluteString)
        
        let selectionImg = isSelected ? UIImage(named: "checkbox - completed")! : UIImage(named: "checkbox - normal")!
        
        self.selectBox.image = selectionImg
        
    }
}
