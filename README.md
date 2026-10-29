[English](./README.en.md) | [正體中文](./README.md)

# [WWSceneActivation](https://swiftpackageindex.com/William-Weng)

[![Swift-5.10](https://img.shields.io/badge/Swift-5.10-orange.svg)](https://developer.apple.com/swift/)
[![iOS-17.0](https://img.shields.io/badge/iOS-17.0-pink.svg?style=flat)](https://developer.apple.com/swift/)
![TAG](https://img.shields.io/github/v/tag/William-Weng/WWSceneActivation)
![SPM](https://img.shields.io/badge/SPM-supported-brightgreen.svg)
[![LICENSE](https://img.shields.io/badge/LICENSE-MIT-yellow.svg?style=flat)](https://developer.apple.com/swift/)

`WWSceneActivation` 是一個可重用的 **UIKit 多視窗（Multi-window）啟動輔助工具**。

它將任何符合 `DataSource` 的資料模型包裝成 `NSUserActivity`，再透過 UIKit 的 scene activation API，請求系統啟用既有 `UIWindowScene`，或在需要時建立新的視窗。

https://github.com/user-attachments/assets/d62a9ed5-7fe4-47a0-b6b5-679e20313527

## ✨ 特色

- 將文件、專案、訊息等資料模型抽象成可開啟的 `DataSource`
- 自動建立 `NSUserActivity`，攜帶內容 ID 與標題
- 支援 `targetContentIdentifier`，協助系統配對或聚焦既有視窗
- 支援宣告式 `UIWindowScene.ActivationConfiguration`
- 支援命令式 `UIApplication.activateSceneSession(for:errorHandler:)`

## 📦 安裝設定

### 使用 Swift Package Manager

在 Xcode 中選擇：

`File` → `Add Package Dependencies...`

接著輸入套件 repository URL，選擇要使用的版本，並將套件加入 App target。

如果這是本地套件，也可以在 Xcode 中使用：

`File` → `Add Package Dependencies...` → `Add Local...`

安裝完成後，將該套件匯入目標後，就可以使用了：

```swift
import WWSceneActivation
```

### 啟用多視窗

在 app target 的 `Info.plist` 加入：

```xml
<key>UIApplicationSceneManifest</key>
<dict>
    <key>UIApplicationSupportsMultipleScenes</key>
    <true/>
    <key>UISceneConfigurations</key>
    <dict>
        <key>UIWindowSceneSessionRoleApplication</key>
        <array>
            <dict>
                <key>UISceneConfigurationName</key>
                <string>Default Configuration</string>
                <key>UISceneDelegateClassName</key>
                <string>$(PRODUCT_MODULE_NAME).SceneDelegate</string>
            </dict>
        </array>
    </dict>
</dict>
```

`UIApplicationSupportsMultipleScenes` 設為 `true` 時，系統才可能為 app 建立多個同時存在的 scene；設為 `false` 時，UIKit 不會建立超過一個 scene。

### 注意共用資料

多個 scene 可能同時存取同一份資料。若你的 app 使用共用 store、cache、資料庫連線或其他可變狀態，必須自行同步存取，避免資料競爭或不一致。

## 📚 API 總覽

| 方法 | 說明 |
| --- | --- |
| `supportsMultipleScenes` | 目前應用程式是否支援同時開啟多個 scene / 視窗。 |
| `init(activityType:keyID:)` | 建立一個多視窗啟動輔助物件。 |
| `makeConfiguration(for:)` | 建立可供宣告式 scene activation API 使用的設定。 |
| `makeRequest(for:requestingScene:)` | 建立可供 UIApplication.activateSceneSession(for:errorHandler:) 使用的 scene session activation request。 |
| `requestSceneActivation(for:requestingScene:errorHandler:)` | 向系統請求為指定內容啟用 scene session。 |

## 🧩 DataSource

要開啟為新視窗的資料模型必須符合：

```swift
public protocol DataSource: Identifiable, Hashable {
    var activityIdentifier: String { get }
    var title: String { get }
}
```

| 屬性 | 用途 |
|---|---|
| `id` | 來自 `Identifiable`，用來識別資料模型。 |
| `activityIdentifier` | 寫入 `NSUserActivity.targetContentIdentifier` 與 `userInfo` 的內容 ID。 |
| `title` | 顯示在 `NSUserActivity.title` 的標題，例如文件名稱。 |

## 🧠 核心概念

```text
DataSource
   ↓
NSUserActivity
   ↓
ActivationConfiguration / UISceneSessionActivationRequest
   ↓
UIApplication.activateSceneSession(...)
   ↓
系統啟用既有 scene，或建立新 scene
   ↓
SceneDelegate 根據 activity 開啟對應內容
```

`NSUserActivity` 是 scene activation 的內容載體；`UISceneSessionActivationRequest` 則描述要啟用哪種 scene session、攜帶哪個 activity，以及額外的啟動選項。


## 🧪 使用範例

### SceneDelegate.swift

```swift
import UIKit

final class SceneDelegate: UIResponder, UIWindowSceneDelegate {
    
    var window: UIWindow?

    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        
        guard scene is UIWindowScene else { return }
        guard let activity = connectionOptions.userActivities.first(where: { $0.activityType == ViewController.activityType }) else { return }
        
        showDocument(from: activity)
    }
    
    func scene(_ scene: UIScene,continue userActivity: NSUserActivity) {
        showDocument(from: userActivity)
    }
}

private extension SceneDelegate {
    
    func showDocument(from activity: NSUserActivity) {
        
        guard let document = document(from: activity),
              let window
        else {
            return
        }
        
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        
        guard let controller = storyboard.instantiateViewController(withIdentifier: "DetailViewController") as? DetailViewController else {
            fatalError("請確認 Main.storyboard 的詳情頁：Class 與 Storyboard ID 都是 DetailViewController。")
        }
        
        controller.document = document
        window.rootViewController = UINavigationController(rootViewController: controller)
    }
    
    func document(from activity: NSUserActivity) -> Document? {
        
        guard activity.activityType == ViewController.activityType,
              let documentID = activity.userInfo?[ViewController.userInfoKey] as? String
        else {
            return nil
        }
        
        return DocumentStore.document(withID: documentID)
    }
}
```

### ViewController.swift

```swift
import UIKit
import WWSceneActivation

final class ViewController: UIViewController {

    @IBOutlet private weak var tableView: UITableView!
    
    static let activityType = "com.example.MultiWindowDemo.openDocument"
    static let userInfoKey = "com.example.MultiWindowDemo.documentID"
    
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

extension ViewController: UITableViewDataSource {

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        documents.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "TableViewCell", for: indexPath) as? TableViewCell else {
            fatalError("請確認 prototype cell 的 Class 是 TableViewCell，Reuse Identifier 是 TableViewCell。")
        }

        cell.configure(with: documents[indexPath.row])
        return cell
    }
}

extension ViewController: UITableViewDelegate {

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        showDocument(documents[indexPath.row])
    }

    func tableView(_ tableView: UITableView, contextMenuConfigurationForRowAt indexPath: IndexPath, point: CGPoint) -> UIContextMenuConfiguration? {
        
        let document = documents[indexPath.row]

        return UIContextMenuConfiguration(identifier: nil, previewProvider: nil) { [weak self] _ in
            
            guard let self else { return UIMenu(children: []) }
            
            let action = self.menuActionMaker(with: document)
            return UIMenu(children: [action])
        }
    }
}

private extension ViewController {
    
    func menuActionMaker(with dataSource: any WWSceneActivation.DataSource) -> UIWindowScene.ActivationAction {
        
        let action = UIWindowScene.ActivationAction(title: "在新視窗開啟", image: UIImage(systemName: "rectangle.on.rectangle"), identifier: nil, discoverabilityTitle: nil, attributes: [], alternate: nil, { _ -> UIWindowScene.ActivationConfiguration? in
            self.sceneActivation.makeConfiguration(for: dataSource)
        })
        
        return action
    }
    
    func requestNewWindow(for dataSource: any WWSceneActivation.DataSource) {
        
        sceneActivation.requestSceneActivation(for: dataSource, requestingScene: view.window?.windowScene) { [weak self] error in
            Task { @MainActor [weak self] in
                self?.showMessage(error.localizedDescription)
            }
        }
    }
}

private extension ViewController {

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
    
    func showMessage(_ message: String) {
        
        let alert = UIAlertController(title: "Scene Activation", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))

        present(alert, animated: true)
    }
}
```
