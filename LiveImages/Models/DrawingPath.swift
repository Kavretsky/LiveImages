//
//  DrawingPath.swift
//  LiveImages
//
//  Created by Nikolay Kavretsky on 28.10.2024.
//

import Foundation
import SwiftUI

enum DrawingPathType: Equatable {
    case fill
    case erase
}

struct DrawingPath: Identifiable, Equatable {
    let id = UUID().uuidString
    var points: [CGPoint]
    var color: Color
    let lineWidth: CGFloat
    let type: DrawingPathType
}
