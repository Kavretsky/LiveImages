//
//  DrawingPath.swift
//  LiveImages
//
//  Created by Nikolay Kavretsky on 28.10.2024.
//

import Foundation
import SwiftUI

enum DrawingPathType {
    case fill
    case erase
}

struct DrawingPath: Identifiable {
    let id = UUID()
    var points: [CGPoint]
    var color: Color
    let lineWidth: CGFloat
    let type: DrawingPathType
}
