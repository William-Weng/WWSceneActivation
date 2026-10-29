//
//  DetailViewController.swift
//  MultipleScenesDemo
//
//  Created by William.Weng on 2026/10/28.
//

import UIKit

final class DetailViewController: UIViewController {

    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var bodyLabel: UILabel!

    var document: Document?

    override func viewDidLoad() {
        super.viewDidLoad()
        configureContent()
    }
}

private extension DetailViewController {
    
    func configureContent() {
        
        initTitle()
        titleLabel.text = "沒有文件"
        bodyLabel.text = nil
        
        guard let document else { return }

        titleLabel.text = document.title
        bodyLabel.text = document.body
    }
    
    func initTitle() {
        
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "zh_TW")
        formatter.timeZone = .current
        formatter.dateFormat = "HH:mm:ss.SSS"
        
        title = "開啟於 \(formatter.string(from: .now))"
    }
}
