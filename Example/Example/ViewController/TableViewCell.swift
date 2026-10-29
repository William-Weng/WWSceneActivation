//
//  TableViewCell.swift
//  MultipleScenesDemo
//
//  Created by William.Weng on 2026/10/28.
//

import UIKit

final class TableViewCell: UITableViewCell {

    @IBOutlet private weak var titleLabel: UILabel!
    @IBOutlet private weak var detailLabel: UILabel!

    func configure(with document: Document) {        
        titleLabel.text = document.title
        detailLabel.text = document.body
    }
}
