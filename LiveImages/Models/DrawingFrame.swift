//
//  DrawingFrame.swift
//  LiveImages
//
//  Created by Nikolay Kavretsky on 28.10.2024.
//

import Foundation

struct DrawingFrame: Identifiable {
    let id = UUID()
    var name: String
    var pathHead: PathNode? {
        dummy.next
    }
    
    init(name: String) {
        self.name = name
        
    }
    private var dummy = PathNode()
    
    func appendPath(_ node: PathNode) {
        node.next = dummy.next
        dummy.next = node
    }
    
}
