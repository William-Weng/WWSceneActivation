[English](./README.en.md) | [正體中文](./README.md)

# [WWSceneActivation](https://swiftpackageindex.com/William-Weng)

[![Swift-5.10](https://img.shields.io/badge/Swift-5.10-orange.svg)](https://developer.apple.com/swift/)
[![iOS-17.0](https://img.shields.io/badge/iOS-17.0-pink.svg?style=flat)](https://developer.apple.com/swift/)
![TAG](https://img.shields.io/github/v/tag/William-Weng/WWSceneActivation)
![SPM](https://img.shields.io/badge/SPM-supported-brightgreen.svg)
[![LICENSE](https://img.shields.io/badge/LICENSE-MIT-yellow.svg?style=flat)](https://developer.apple.com/swift/)

`WWSceneActivation` is a reusable **UIKit multi-window activation helper**.

It wraps any data model conforming to `DataSource` into an `NSUserActivity`, then uses UIKit’s scene activation APIs to ask the system to activate an existing `UIWindowScene` or create a new window when needed.

https://github.com/user-attachments/assets/d62a9ed5-7fe4-47a0-b6b5-679e20313527

## ✨ Features

- Abstract documents, projects, messages, and other models into an openable `DataSource`
- Automatically creates an `NSUserActivity` carrying a content ID and title
- Supports `targetContentIdentifier` to help the system match or focus an existing window
- Supports declarative `UIWindowScene.ActivationConfiguration`
- Supports imperative `UIApplication.activateSceneSession(for:errorHandler:)`

## 📦 Installation

### Swift Package Manager

In Xcode, choose:

`File` → `Add Package Dependencies...`

Then enter the package repository URL, select the version you want to use, and add the package to your app target.

If this is a local package, you can also use:

`File` → `Add Package Dependencies...` → `Add Local...`

After installation, import the package in the target where you want to use it:

```swift
import WWSceneActivation
```

### Enable Multiple Windows

Add the following to your app target’s `Info.plist`:

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

Set `UIApplicationSupportsMultipleScenes` to `true` to allow the system to create multiple simultaneously active scenes for your app. If it is `false`, UIKit will not create more than one scene.

### Shared Data

Multiple scenes may access the same data at the same time. If your app uses a shared store, cache, database connection, or other mutable state, coordinate access yourself to avoid data races or inconsistent state.

## 📚 API Overview

### Public Function

| API | Description |
| --- | --- |
| `closeScene(_:errorHandler:)` | Closes the specified `UIScene`. Requests that the system destroy the scene and its associated `UISceneSession`. The system may delay or reject the request, so use `errorHandler` to handle failures. |
| `closeWindowScene(_:errorHandler:)` | Closes the specified `UIWindowScene`. This is a convenience wrapper around `closeScene(_:errorHandler:)` with a more specific window-scene type. |
| `closeAllScenes(except:errorHandler:)` | Keeps only the specified `UIScene` and closes all other connected scenes. Useful when non-window scenes may also be present. |
| `closeAllWindowScenes(except:errorHandler:)` | Keeps only the specified `UIWindowScene` and closes all other connected window scenes. Useful for collapsing a multi-window app to a single specified window. |
| `init(activityType:keyID:)` | Creates a multi-window activation helper. |
| `makeConfiguration(for:)` | Creates an activation configuration for declarative scene activation APIs. |
| `makeRequest(for:requestingScene:)` | Creates a scene session activation request for `UIApplication.activateSceneSession(for:errorHandler:)`. |
| `requestSceneActivation(for:requestingScene:errorHandler:)` | Asks the system to activate a scene session for the given content. |

### Public Properties

| Property | Type | Description |
| --- | --- | --- |
| `supportsMultipleScenes` | `Bool` | Whether the app currently supports opening multiple scenes / windows simultaneously. |
| `connectedScenes` | `Set<UIScene>` | All scenes currently connected to the app, including foreground and background scenes. |
| `connectedWindowScenes` | `[UIWindowScene]` | The currently connected window scenes; filters `UIScene` instances and casts them to `UIWindowScene`. |
| `foregroundActiveWindowScenes` | `[UIWindowScene]` | Window scenes currently displayed in the foreground and actively receiving events. |
| `foregroundWindowScenes` | `[UIWindowScene]` | Window scenes currently in the foreground, including both `foregroundActive` and temporarily `foregroundInactive` scenes. |
| `backgroundWindowScenes` | `[UIWindowScene]` | Window scenes currently in the background; their UI is not visible, but they may retain state or handle system events. |
| `keyWindowScene` | `UIWindowScene?` | The window scene that currently owns the key window. |
| `foregroundActiveKeyWindowScene` | `UIWindowScene?` | A foreground-active window scene that owns the key window. |
| `keyWindow` | `UIWindow?` | The current key window. |

### Activation States

| State | Description |
| --- | --- |
| `foregroundActive` | The scene is in the foreground and is currently receiving events; this usually represents the window the user is interacting with. |
| `foregroundInactive` | The scene is in the foreground but temporarily not receiving events, such as while Control Center, Notification Center, or the app switcher is presented. |
| `background` | The scene has moved to the background; its UI is not visible, but it may retain state, handle certain system events, or return to the foreground later. |
| `unattached` | The scene is not yet attached to a session; this is usually a transitional state. |

### Multi-Window Notes

- On iPadOS, multiple `UIWindowScene` instances can be `foregroundActive` at the same time, so `foregroundActiveWindowScenes` may return more than one scene.
- `connectedScenes` includes both foreground and background scenes that remain in memory. Use `foregroundActiveWindowScenes` when working with UI that is visible and interactive.
- The key window receives keyboard events and other events without a relevant coordinate. In a multi-scene app, query `UIWindowScene.keyWindow` instead of the deprecated `UIApplication.shared.keyWindow`.
- Background scenes should not be treated as visible or generally interactive UI. They can also be disconnected by the system to reclaim resources, so avoid relying on them to preserve unique long-term state.

## 🧩 DataSource

A data model must conform to the following protocol to be opened in a new window:

```swift
public protocol DataSource: Identifiable, Hashable {
    var activityIdentifier: String { get }
    var title: String { get }
}
```

| Property | Purpose |
|---|---|
| `id` | Comes from `Identifiable` and identifies the data model. |
| `activityIdentifier` | The content ID written to `NSUserActivity.targetContentIdentifier` and `userInfo`. |
| `title` | The title shown in `NSUserActivity.title`, such as a document name. |

### Example

```swift
struct Document: WWSceneActivation.DataSource {
    let id: UUID
    var title: String
}

extension Document {
    var activityIdentifier: String {
        "com.example.App/document/\(id.uuidString)"
    }
}
```

Use a stable and unique string for `activityIdentifier`, such as a path-like identifier that includes both the content type and ID:

```text
com.example.App/document/6F9A...-...
com.example.App/project/42
com.example.App/message/981
```

## 🧠 Core Concept

```text
DataSource
   ↓
NSUserActivity
   ↓
ActivationConfiguration / UISceneSessionActivationRequest
   ↓
UIApplication.activateSceneSession(...)
   ↓
The system activates an existing scene or creates a new scene
   ↓
SceneDelegate opens the corresponding content from the activity
```

`NSUserActivity` carries the content for scene activation, while `UISceneSessionActivationRequest` describes the target scene session, the activity to deliver, and additional activation options.

## 🧪 Example

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
