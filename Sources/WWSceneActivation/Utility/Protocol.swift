//
//  Protocol.swift
//  WWSceneActivation
//
//  Created by William.Weng on 2026/10/29.
//

import Foundation

extension WWSceneActivation {
    
    public protocol DataSource: Identifiable, Hashable {
        var activityIdentifier: String { get }  // 用來表示目標內容的字串識別碼 (會被設定為 `NSUserActivity.targetContentIdentifier`)
        var title: String { get }               // 顯示給使用者看的標題 (會被設定為 `NSUserActivity.title`)
    }
}
