//
//  Enum.swift
//  WWSceneActivation
//
//  Created by William.Weng on 2026/10/29.
//

import Foundation

extension WWSceneActivation {
    
    public enum CustomError: LocalizedError {
        
        case multipleScenesUnsupported
        
        public var errorDescription: String? {
            switch self {
            case .multipleScenesUnsupported: return "目前執行環境不支援多視窗。"
            }
        }
    }
}
