//
//  CustomHeaderView.swift
//  CollectionViewPractice
//
//  Created by Macbook on 2/24/24.
//

import UIKit

class CustomHeaderView: UICollectionReusableView {
    
    
    @IBOutlet weak var selectionInfoLabel: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        print(#fileID, #function, #line, "- ")
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        print(#fileID, #function, #line, "- ")
    }
}
