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
    var paths: [DrawingPath]
}
