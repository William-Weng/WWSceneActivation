//
//  ViewController.swift
//  MultipleScenesDemo
//
//  Created by William.Weng on 2026/10/28.
//

import UIKit
import WWSceneActivation

/// 文件列表頁
///
/// 負責：
/// 1. 顯示 `DocumentStore` 中的文件
/// 2. 點選文件時，在目前 navigation stack 開啟詳情頁
/// 3. 透過 toolbar 按鈕或 context menu，請求系統開啟新的 `UIWindowScene`
final class ViewController: UIViewController {

    @IBOutlet private weak var tableView: UITableView!
    
    static let activityType = "com.example.MultiWindowDemo.openDocument"    // 這個 demo 使用的 `NSUserActivity` 類型 => SceneDelegate 可透過這個字串判斷：「這次 scene activation 是要開啟一份文件」
    static let userInfoKey = "com.example.MultiWindowDemo.documentID"       // `NSUserActivity.userInfo` 中存放文件 ID 的 key => SceneDelegate 之後會用這個 key 取出要顯示的文件 ID
    
    private let documents = DocumentStore.documents
    private let sceneActivation: WWSceneActivation
    
    init() {
        sceneActivation = .init(activityType: Self.activityType, keyID: Self.userInfoKey)
        super.init()
    }
    
    required init?(coder: NSCoder) {
        sceneActivation = .init(activityType: Self.activityType, keyID: Self.userInfoKey)
        super.init(coder: coder)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.dataSource = self
        tableView.delegate = self
    }

    @IBAction private func appendScene(_ sender: UIBarButtonItem) {
        guard let document = documents.first else { return }
        requestNewWindow(for: document)
    }
}

// MARK: - UITableViewDataSource
extension ViewController: UITableViewDataSource {

    /// 列表列數等於文件數量
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        documents.count
    }
    
    /// 設定每一列的 cell 內容
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "TableViewCell", for: indexPath) as? TableViewCell else {
            fatalError("請確認 prototype cell 的 Class 是 TableViewCell，Reuse Identifier 是 TableViewCell。")
        }

        cell.configure(with: documents[indexPath.row])
        return cell
    }
}

// MARK: - UITableViewDelegate
extension ViewController: UITableViewDelegate {

    /// 點選某一列文件
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        showDocument(documents[indexPath.row])
    }

    /// 為每一列提供長按 context menu
    func tableView(_ tableView: UITableView, contextMenuConfigurationForRowAt indexPath: IndexPath, point: CGPoint) -> UIContextMenuConfiguration? {
        
        let document = documents[indexPath.row]

        return UIContextMenuConfiguration(identifier: nil, previewProvider: nil) { [weak self] _ in
            
            guard let self else { return UIMenu(children: []) }
            
            let action = self.menuActionMaker(with: document)
            return UIMenu(children: [action])
        }
    }
}

// MARK: - 小工具
private extension ViewController {
    
    /// 建立一個「在新視窗開啟」的 context menu action
    ///
    /// `UIWindowScene.ActivationAction` 是 UIKit 提供的 menu element，專門用來向系統請求啟用新的 `UIWindowScene`
    ///
    /// - Parameter document: 使用者長按的文件
    /// - Returns: 可放進 `UIMenu` 的 activation action
    func menuActionMaker(with dataSource: any WWSceneActivation.DataSource) -> UIWindowScene.ActivationAction {
        
        let action = UIWindowScene.ActivationAction(title: "在新視窗開啟", image: UIImage(systemName: "rectangle.on.rectangle"), identifier: nil, discoverabilityTitle: nil, attributes: [], alternate: nil, { _ -> UIWindowScene.ActivationConfiguration? in
            self.sceneActivation.makeConfiguration(for: dataSource)
        })
        
        return action
    }
    
    /// 為指定資料內容請求開啟新視窗
    ///
    /// - Parameter dataSource: 要在新視窗顯示的資料模型
    func requestNewWindow(for dataSource: any WWSceneActivation.DataSource) {
        
        sceneActivation.requestSceneActivation(for: dataSource, requestingScene: view.window?.windowScene) { [weak self] error in
            Task { @MainActor [weak self] in
                self?.showMessage(error.localizedDescription)
            }
        }
    }
}

// MARK: - 小工具
private extension ViewController {

    /// 在目前的 navigation stack 中開啟文件詳情頁
    ///
    /// - Parameter document: 要在詳情頁顯示的文件
    func showDocument(_ document: Document) {
        
        let storyboard = UIStoryboard(name: "Main", bundle: nil)

        guard let controller = storyboard.instantiateViewController(withIdentifier: "DetailViewController") as? DetailViewController else {
            showMessage("無法開啟文件詳情頁，請確認 Storyboard 設定。"); return
        }
        
        controller.document = document
        
        if let navigationController {
            navigationController.pushViewController(controller, animated: true)
        } else {
            present(UINavigationController(rootViewController: controller), animated: true)
        }
    }
    
    /// 顯示一個簡單的提示或錯誤訊息
    ///
    /// - Parameter message: 要顯示給使用者的文字
    func showMessage(_ message: String) {
        
        let alert = UIAlertController(title: "Scene Activation", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))

        present(alert, animated: true)
    }
}
