//
//  SceneDelegate.swift
//  MultipleScenesDemo
//
//  Created by William.Weng on 2026/10/28.
//

import UIKit

/// 這個 app 的 scene delegate
///
/// 負責管理單一 `UIWindowScene` 的視窗與 UI，並處理透過 `NSUserActivity` 傳入的「開啟文件」請求
final class SceneDelegate: UIResponder, UIWindowSceneDelegate {
    
    var window: UIWindow?   ///這個 scene 管理的主要視窗
    
    /// 當新的 scene 建立或重新連接時呼叫
    ///
    /// 這是設定 scene 初始 UI 的地方
    ///
    /// 若這個 scene 是因為「開啟某份文件」而建立，`connectionOptions.userActivities` 會包含對應的 `NSUserActivity`；此時直接把詳情頁設為 root view controller
    ///
    /// - Parameters:
    ///   - scene: 系統建立的 scene
    ///   - session: 管理這個 scene 的 session
    ///   - options: scene 連接時系統附帶的資訊，例如 user activities、URL contexts、shortcut items 等
    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        
        guard scene is UIWindowScene else { return }
        guard let activity = connectionOptions.userActivities.first(where: { $0.activityType == ViewController.activityType }) else { return }
        
        showDocument(from: activity)
    }
    
    /// 當一個已存在的 scene 收到新的 user activity 時呼叫
    ///
    /// 例如：
    /// - app 已在執行，使用者要求為某份文件開啟新視窗
    /// - 系統決定把某個 activity 路由到這個既有 scene
    ///
    /// - Parameters:
    ///   - scene: 收到 activity 的 scene。
    ///   - userActivity: 系統傳入、描述要繼續或顯示內容的 activity。
    func scene(_ scene: UIScene,continue userActivity: NSUserActivity) {
        showDocument(from: userActivity)
    }
}

// MARK: - 小工具
private extension SceneDelegate {
    
    /// 根據 `NSUserActivity` 顯示對應文件
    ///
    /// 這個方法會：
    /// 1. 驗證 activity type
    /// 2. 從 `userInfo` 取出文件 ID
    /// 3. 從 `DocumentStore` 找出文件
    /// 4. 建立 `DetailViewController`
    /// 5. 將它包在 `UINavigationController` 中，並設為這個 scene 的 root view controller
    ///
    /// - Parameter activity: 描述要開啟文件的 user activity
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
    
    /// 從 `NSUserActivity` 解析出要顯示的文件
    ///
    /// 這個方法負責驗證 activity 是否為「開啟文件」類型，並從 `userInfo` 取出文件 ID，再向 `DocumentStore` 查詢文件
    ///
    /// - Parameter activity: 系統傳入、描述要繼續顯示內容的 user activity
    /// - Returns: 若 activity 有效且能找到對應文件，回傳該文件；否則回傳 `nil`
    func document(from activity: NSUserActivity) -> Document? {
        
        guard activity.activityType == ViewController.activityType,
              let documentID = activity.userInfo?[ViewController.userInfoKey] as? String
        else {
            return nil
        }
        
        return DocumentStore.document(withID: documentID)
    }
}
