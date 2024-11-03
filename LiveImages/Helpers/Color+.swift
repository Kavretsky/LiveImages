//
//  Color+.swift
//  LiveImages
//
//  Created by Nikolay Kavretsky on 03.11.2024.
//

import SwiftUI

extension Color {
    static func randomColor() -> Color {
        Color(.init(hue: .random(in: 0...1), saturation: .random(in: 0...1), brightness: .random(in: 0...1), alpha: 1))
    }
}
