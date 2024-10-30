//
//  DrawingFrame.swift
//  LiveImages
//
//  Created by Nikolay Kavretsky on 28.10.2024.
//

import Foundation
import SwiftUI

struct DrawingFrame: Identifiable, Equatable {
    let id = UUID().uuidString
    var name: String
    var image: Image?
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
    
    func removeFirst() {
        dummy.next = dummy.next?.next
    }
    
    static func == (lhs: DrawingFrame, rhs: DrawingFrame) -> Bool {
        lhs.id == rhs.id
    }
    
}
