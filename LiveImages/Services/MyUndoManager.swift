//
//  MyUndoManager.swift
//  LiveImages
//
//  Created by Nikolay Kavretsky on 29.10.2024.
//

import Observation

@Observable
final class MyUndoManager {
    private var undoStackHash = [String : [() -> Void]]()
    private var redoStackHash = [String : [() -> Void]]()
    
    func registerUndo(frameID: String, removePrevious: Bool = false, _ closure: @escaping () -> Void) {
        undoStackHash[frameID, default: []].append(closure)
        if removePrevious {
            redoStackHash[frameID] = []
        }
    }
    func registerRedu(frameID: String, _ closure: @escaping () -> Void) {
        redoStackHash[frameID, default: []].append(closure)
    }
    
    func undo(for frameID: String) {
        guard !undoStackHash[frameID, default: []].isEmpty else { return }
        undoStackHash[frameID, default: []].removeLast()()
    }
    
    func redo(for frameID: String) {
        guard !redoStackHash[frameID, default: []].isEmpty else { return }
        redoStackHash[frameID, default: []].removeLast()()
    }
    
    func canRedo(for frameID: String) -> Bool {
        !redoStackHash[frameID, default: []].isEmpty
    }
    
    func canUndo(for frameID: String) -> Bool {
        !undoStackHash[frameID, default: []].isEmpty
    }
    
    func clearStack(for frameID: String) {
        undoStackHash[frameID] = []
        redoStackHash[frameID] = []
    }
    
    
}
