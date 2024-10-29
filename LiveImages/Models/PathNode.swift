//
//  PathNode.swift
//  LiveImages
//
//  Created by Nikolay Kavretsky on 29.10.2024.
//

class PathNode {
    var erasePath: DrawingPath?
    var next: PathNode? = nil
    var drawingPaths: [DrawingPath] = []
    
    init(erasePath: DrawingPath? = nil, next: PathNode? = nil, drawingPaths: [DrawingPath] = []) {
        self.erasePath = erasePath
        self.next = next
        self.drawingPaths = drawingPaths
    }
}
