//
//  UploadManager.swift
//  hippo-internal
//
//  Created by Nick Sloan on 10/8/24.
//
import Collections

class UploadManager {
    var uploadQueue: Deque<String> = .init()
    
    var isRunning: Bool = false
    
    func enqueue(_ referenceID: String) {
        uploadQueue.append(referenceID)
    }
    
    func startProcessing() {
    }
    
    
}
