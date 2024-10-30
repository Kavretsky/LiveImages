//
//  FrameStore.swift
//  LiveImages
//
//  Created by Nikolay Kavretsky on 28.10.2024.
//

import Foundation
import Observation
import SwiftUI

@Observable
final class FrameStore {
    var frames: [DrawingFrame] = [.init(name: "Frame 1")]
    private let undoManager = MyUndoManager()
    
    private(set) var currentFrameIndex = 0
    
    func removeFrame() {
        clearCurrent()
        if currentFrameIndex > 0 {
            currentFrameIndex -= 1
        }
    }
    
    func clearCurrent() {
        undoManager.clearStack(for: frames[currentFrameIndex].id)
        frames[currentFrameIndex] = .init(name: "Frame \(frames.count)")
    }
    
    func addFrame() {
        if currentFrameIndex + 1 == frames.count  {
            frames.append(.init(name: "Frame \(frames.count + 1)"))
        }
        currentFrameIndex += 1
    }
    
    private func addPath(_ path: DrawingPath, to frameIndex: Int) {
        guard frameIndex < frames.count, frameIndex >= 0 else { return }
        
        
        
        guard frames[frameIndex].pathHead != nil else {
            let nextPath = PathNode(erasePath: path.type == .erase ? path : nil, drawingPaths: path.type == .erase ? [] : [path])
            frames[frameIndex].appendPath(nextPath)
            return
        }
        
        switch path.type {
        case .erase:
            if frames[frameIndex].pathHead?.erasePath == nil {
                frames[frameIndex].pathHead?.erasePath = path
            } else {
                let nextPath = PathNode(erasePath: path)
                frames[frameIndex].appendPath(nextPath)
            }
        case .fill:
            if frames[frameIndex].pathHead?.erasePath == nil {
                frames[frameIndex].pathHead?.drawingPaths.append(path)
            } else {
                let nextPath = PathNode(drawingPaths: [path])
                frames[frameIndex].appendPath(nextPath)
            }
        }
    }
    
    
    private func removePath(_ path: DrawingPath, from frameIndex: Int) {
        guard frameIndex < frames.count, frameIndex >= 0 else { return }
        guard frames[frameIndex].pathHead != nil else { return }
        
        if frames[frameIndex].pathHead?.erasePath == path {
            frames[frameIndex].pathHead?.erasePath = nil
        }
        if frames[frameIndex].pathHead?.drawingPaths.last == path {
            frames[frameIndex].pathHead?.drawingPaths.removeLast()
        }
        if frames[frameIndex].pathHead?.drawingPaths.count == 0 && frames[frameIndex].pathHead?.erasePath == nil {
            frames[frameIndex].removeFirst()
        }
    }
    
    func addPathWithUndo(_ path: DrawingPath, clearRedo: Bool = false) {
        addPath(path, to: currentFrameIndex)
        undoManager.registerUndo(frameID: frames[currentFrameIndex].id, removePrevious: clearRedo) { [weak self] in
            self?.removePathWithUndo(path)
        }
    }
    
    private func removePathWithUndo(_ path: DrawingPath) {
        removePath(path, from: currentFrameIndex)
        undoManager.registerRedu(frameID: frames[currentFrameIndex].id) { [weak self] in
            self?.addPathWithUndo(path)
        }
    }
    
    var canRedo: Bool {
        undoManager.canRedo(for: frames[currentFrameIndex].id)
    }
    
    var canUndo: Bool {
        undoManager.canUndo(for: frames[currentFrameIndex].id)
    }
    
    func undo() {
        undoManager.undo(for: frames[currentFrameIndex].id)
    }
    
    func redo() {
        undoManager.redo(for: frames[currentFrameIndex].id)
    }
    
}
