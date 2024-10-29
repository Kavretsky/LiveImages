//
//  FrameStore.swift
//  LiveImages
//
//  Created by Nikolay Kavretsky on 28.10.2024.
//

import Foundation
import Observation


class FrameStore: ObservableObject {
    @Published var frames: [DrawingFrame] = [.init(name: "Frame 1", paths: [])]
    
}
