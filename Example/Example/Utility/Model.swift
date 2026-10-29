//
//  Model.swift
//  MultipleScenesDemo
//
//  Created by William.Weng on 2026/10/28.
//

import Foundation
import WWSceneActivation

struct Document: WWSceneActivation.DataSource {
    
    let id: UUID = .init()
    let activityIdentifier: String
    let title: String
    let body: String
}

enum DocumentStore {
    
    static let documents: [Document] = [
        Document(activityIdentifier: "doc-1", title: "Swift Concurrency", body: "Actors, tasks, structured concurrency, and Sendable."),
        Document(activityIdentifier: "doc-2", title: "AVFoundation", body: "Playback, recording, media sessions, and audio processing."),
        Document(activityIdentifier: "doc-3", title: "Defold Game Development", body: "Lua scripting, scenes, input, and reusable game modules.")
    ]

    static func document(withID activityIdentifier: String) -> Document? {
        documents.first { $0.activityIdentifier == activityIdentifier }
    }
}
