//
//  MyUndoManager.swift
//  LiveImages
//
//  Created by Nikolay Kavretsky on 29.10.2024.
//

import Observation

@Observable
class MyUndoManager {
    private var undoStack: [() -> Void] = []
    private var redoStack: [() -> Void] = []
    
    func registerUndo(operation: String, removePrevious: Bool = false, _ closure: @escaping () -> Void) {
        undoStack.append(closure)
        if removePrevious {
            redoStack = []
        }
    }
    func registerRedu(operation: String, _ closure: @escaping () -> Void) {
        redoStack.append(closure)
    }
    
    func undo() {
        guard !undoStack.isEmpty else { return }
        undoStack.removeLast()()
    }
    
    func redo() {
        guard !redoStack.isEmpty else { return }
        redoStack.removeLast()()
    }
    
    var canRedo: Bool {
        !redoStack.isEmpty
    }
    
    var canUndo: Bool {
        !undoStack.isEmpty
    }
    
    
}
