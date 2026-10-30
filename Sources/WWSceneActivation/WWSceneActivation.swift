//
//  WWSceneActivation.swift
//  WWSceneActivation
//
//  Created by William.Weng on 2026/10/29.
//

import UIKit

/// 可重用的多視窗（Multi-window）啟動輔助工具
///
/// `WWSceneActivation` 將一個符合 `DataSource` 的資料模型包裝成 `NSUserActivity`，再透過 UIKit 的 scene activation API 請求系統建立或啟用一個新的 `UIWindowScene`（新視窗）
///
public struct WWSceneActivation {
    
    let activityType: String    // 此 activation 的 activity type
    let userInfoKey: String     // 寫入 `NSUserActivity.userInfo` 時使用的 key
    
    /// 建立一個多視窗啟動輔助物件
    ///
    /// - Parameters:
    ///   - activityType: `NSUserActivity.activityType`，用來識別「開啟某類內容」的 activity
    ///   - userInfoKey: `userInfo` 的 key，用來攜帶實際要開啟的內容 ID
    public init(activityType: String, keyID: String) {
        self.activityType = activityType
        self.userInfoKey = keyID
    }
}

// MARK: - 公開參數
public extension WWSceneActivation {
    
    /// 目前應用程式是否支援同時開啟多個 scene / 視窗
    static var supportsMultipleScenes: Bool {
        UIApplication.shared.supportsMultipleScenes
    }
    
    /// 目前應用程式所有已連線的 scenes
    static var connectedScenes: Set<UIScene> {
        UIApplication.shared.connectedScenes
    }
    
    /// 目前擁有 key window 的視窗 scene
    static var keyWindowScene: UIWindowScene? {
        connectedWindowScenes.first { $0.keyWindow != nil }
    }
    
    /// 前景 active 且擁有 key window 的視窗 scene
    static var foregroundActiveKeyWindowScene: UIWindowScene? {
        foregroundActiveWindowScenes.first { $0.keyWindow != nil }
    }
    
    /// 目前的 key window
    static var keyWindow: UIWindow? {
        keyWindowScene?.keyWindow
    }
    
    /// 目前已連線的視窗 scenes
    static var connectedWindowScenes: [UIWindowScene] {
        connectedScenes.compactMap { $0 as? UIWindowScene }
    }
    
    /// 目前正在前景顯示、且正在接收事件的視窗 scenes
    static var foregroundActiveWindowScenes: [UIWindowScene] {
        connectedWindowScenes.filter { $0.activationState == .foregroundActive }
    }
    
    /// 目前仍在背景的視窗 scenes
    static var backgroundWindowScenes: [UIWindowScene] {
        connectedWindowScenes.filter { $0.activationState == .background }
    }
    
    /// 目前位於前景的視窗 scenes（包含 active 與暫時 inactive）
    static var foregroundWindowScenes: [UIWindowScene] {
        let foregroundStates: Set<UIScene.ActivationState> = [.foregroundActive, .foregroundInactive]
        return connectedWindowScenes.filter { foregroundStates.contains($0.activationState) }
    }
}

// MARK: - 公開函式
public extension WWSceneActivation {
    
    /// 建立可供宣告式 scene activation API 使用的設定
    ///
    /// - Parameter dataSource: 要在新視窗中顯示的資料模型
    /// - Returns: 包含 `NSUserActivity` 的視窗啟動設定
    func makeConfiguration<T: DataSource>(for dataSource: T) -> UIWindowScene.ActivationConfiguration {
        UIWindowScene.ActivationConfiguration(userActivity: makeActivity(for: dataSource))
    }
    
    /// 建立可供 `UIApplication.activateSceneSession(for:errorHandler:)` 使用的 scene session activation request
    ///
    /// - Parameters:
    ///   - dataSource: 要在新視窗中顯示的資料模型
    ///   - requestingScene: 發起這次請求的既有視窗 scene；若是 `nil`，表示沒有特別指定來源 scene
    /// - Returns: 描述目標視窗、activity 與選項的 activation request
    func makeRequest<T: DataSource>(for dataSource: T, requestingScene: UIWindowScene? = nil) -> UISceneSessionActivationRequest {
        
        let options = UIScene.ActivationRequestOptions()
        options.requestingScene = requestingScene
        
        return UISceneSessionActivationRequest(role: .windowApplication, userActivity: makeActivity(for: dataSource), options: options)
    }
    
    /// 向系統請求為指定內容啟用 scene session
    ///
    /// 系統可能會聚焦已顯示相同內容的既有 scene，也可能會建立新的 `UIWindowScene`
    ///
    /// - Parameters:
    ///   - dataSource: 要在新視窗中顯示的資料模型。
    ///   - requestingScene: 發起這次請求的既有視窗 scene；可為 `nil`
    ///   - errorHandler: scene 啟用失敗時要執行的 handler
    func requestSceneActivation(for dataSource: any DataSource, requestingScene: UIWindowScene?, errorHandler: ((Error) -> Void)? = nil) {
        
        guard Self.supportsMultipleScenes else { errorHandler?(CustomError.multipleScenesUnsupported); return }
        
        let activity = makeActivity(for: dataSource)
        let options = UIScene.ActivationRequestOptions()
        
        options.requestingScene = requestingScene
        
        let request = UISceneSessionActivationRequest(role: .windowApplication, userActivity: activity, options: options)
        UIApplication.shared.activateSceneSession(for: request) { errorHandler?($0) }
    }
}

// MARK: - 小工具
private extension WWSceneActivation {
    
    /// 將資料模型轉換成描述「要在新視窗顯示什麼內容」的 `NSUserActivity`
    ///
    /// `NSUserActivity` 是 scene activation 的內容載體：系統會把它交給目標 scene 的 delegate，SceneDelegate 再根據其中的資訊開啟對應內容
    ///
    /// - Parameter dataSource: 要開啟的資料模型
    /// - Returns: 可用於 scene activation 的 user activity
    func makeActivity<T: DataSource>(for dataSource: T) -> NSUserActivity {
        
        let activity = NSUserActivity(activityType: activityType)
        
        activity.targetContentIdentifier = dataSource.activityIdentifier
        activity.title = dataSource.title
        activity.userInfo = [userInfoKey: dataSource.activityIdentifier]
        
        return activity
    }
}
